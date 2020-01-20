# yc-k8s-elastic

Установка ELK в Облако состоит из трёх этапов: развёртывание кластера в облаке, установка туда операторов и нужных ресурсов, а также установка filebeat'а в остальные кластера k8s. В результате выполнения этой инструкции вы получите отдельный кластер с ELK'ом с двумя endpoint'ами: веб-интерфейсом kibana и запаролленным портом logstash.

Данный гайд нацел на создание кластера из 3 elasticsearch-нод с 4ГБ памяти и 2 ядрами. Данные хранятся на 50ГБ network-ssd дисках

## Развёртывание кластера

Развёртывание кластера через терраформ это необязательно, этот способ просто увеличит ваш контроль над кластером, позволив описать инфраструктуру под него декларативно

1. Устанавливаем terraform согласно [инструкции](https://learn.hashicorp.com/terraform/getting-started/install.html)
2. Инициализируем создание кластера:
```bash
terraform init
terraform apply
```
3. Получаем credentials кластера:
```bash
yc k8s cluster get-credentials elk-k8s-cluster --external
```

## Установка elasticsearch и kibana

Для установки нужно поставить в свежесозданный кластер оператор и создать с его помощью elasticsearch и kibana
```bash
kubectl apply -f 01-operator.yaml

```

Подождём 2-3 минуты пока задеплоится оператор и развернём с его помощью  elasticsearch и kibana:

```bash
kubectl apply -f 02-resources.yaml
```

Ждём пока будет создан LoadBalancer под Logstash и сохраняем его данные в переменные окружения:
```bash
LOGSTASH_HOST=""
while [ -z "${LOGSTASH_HOST}" ]; do LOGSTASH_HOST=$(kubectl -n elastic-system get service logstash -o go-template='{{(index .status.loadBalancer.ingress 0).ip}}') || LOGSTASH_HOST=""; sleep 0.1; done
LOGSTASH_PORT=$(kubectl -n elastic-system get service logstash -o go-template='{{(index .spec.ports 0).port}}')
```

## Генерация сертификатов

Для того, чтобы иметь возможность писать логи из других кластеров для logstash'а нужно сгенерировать CA, и сертификат для самого logstash. Для этого потребуется утилита cfssl.

На MAC OS X её можно поставить через Homebrew:
```bash
brew install cfssl
```

На Linux'е скачать подходящие бинарные файлы и поставить их в /usr/local/bin:
```bash
wget -q --show-progress --https-only --timestamping \
  https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/linux/cfssl \
  https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/linux/cfssljson
chmod +x cfssl cfssljson
sudo mv cfssl cfssljson /usr/local/bin/
```

Теперь можно сгенерить нужные сертификаты и загрузить их как секреты:
```bash
cd certs
cfssl gencert \
    -initca \
    -config=ca-config.json \
    ca-csr.json | cfssljson -bare ca
cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=beats \
    -hostname=${LOGSTASH_HOST} \
    logstash-csr.json | cfssljson -bare logstash
openssl pkcs8 -topk8 -nocrypt -in logstash-key.pem -out logstash.key
kubectl create secret generic -n elastic-system beats-certs --from-file=./ca.pem --from-file=./logstash.pem --from-file=./logstash.key
cd ..
```

## Установка logstash и filebeat в кластер с elasticsearch

Сохраненим информацию о текущем кластере в ConfigMap:
```bash
CLUSTER_ID=$(kubectl config current-context | sed 's/^yc-managed-k8s-//')
CLUSTER_NAME=$(yc k8s cluster get --id ${CLUSTER_ID} --format yaml | grep name: | awk '{ print $2; }')
kubectl create configmap cluster-info -n elastic-system --from-literal cluster-id=${CLUSTER_ID} --from-literal cluster-name=${CLUSTER_NAME}
```

Теперь можно поставить в кластер filebeat и logstash:
```bash
kubectl apply -f 03-internal.yaml
```

Сохраним IP адрес и порт logstash'а в env переменных:
## Подключение к kibana

Чтобы проверить работоспособность стека нужно подключится к Kibana, для начала вычислим её адрес:

```bash
kubectl -n elastic-system get service es-log-kb-http -o go-template='https://{{(index .status.loadBalancer.ingress 0).ip}}:{{(index .spec.ports 0).port}}'
```

И посмотрим пароль:

```bash
kubectl -n elastic-system get secret es-log-es-elastic-user -o go-template='{{.data.elastic | base64decode }}'
```

После подключения к Kibana можно залогинится под пользователем elastic и паролём выше

## Установка filebeat в остальные кластера

Теперь во все кластера, в которых вы хотите собирать логи, нужно установить filebeat. Этот компонент будет собирать все логи из кластера и пересылать их в logstash ELK-кластера.

Для начала переключимся в другой кластер:
```bash
yc k8s cluster get-credentials k8s-cluster --external
```

Сохраненим информацию о текущем кластере в ConfigMap:
```bash
CLUSTER_ID=$(kubectl config current-context | sed 's/^yc-managed-k8s-//')
CLUSTER_NAME=$(yc k8s cluster get --id ${CLUSTER_ID} --format yaml | grep name: | awk '{ print $2; }')
kubectl create configmap cluster-info -n kube-system --from-literal cluster-id=${CLUSTER_ID} --from-literal cluster-name=${CLUSTER_NAME}
```

Сохраняем в ConfigMap адрес logstash'а:
```bash
kubectl create configmap logstash-info -n kube-system --from-literal host=${LOGSTASH_HOST} --from-literal port=${LOGSTASH_PORT}
```

Теперь сгенерим сертификаты для подключения к filebeat. Данная инструкция предполагает, что для каждого кластера будет свой сертификат.
```bash
cd certs
cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=beats \
    filebeat-csr.json | cfssljson -bare filebeat
openssl pkcs8 -topk8 -nocrypt -in filebeat-key.pem -out filebeat.key
kubectl create secret generic -n kube-system beats-certs --from-file=./filebeat.pem --from-file=./filebeat.key --from-file=./ca.pem
cd ..

```

И ставим filebeat в кластер:
```bash
kubectl apply -f 10-external.yaml
```

Теперь можем зайти в kibana и поискать логи по фильтру `kubernetes-cluster.name="k8s-cluster"`:

