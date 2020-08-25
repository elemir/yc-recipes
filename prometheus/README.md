# prometheus

Данный гайд и набор конфигов позволяет поставить в кластер prometheus-operator и собрать доступные системные метрики.

Метрики по pv доступны только для кластеров версии 1.16 и выше, для более старых кластеров можно использовать метрики `container_fs_...`. В виду отсутствия доступа к controller-manager'у и kube-scheduler'у, их метрики для пользователей оператора на данный момент также недоступы.

## Установка оператора

Перед установкой оператора нужно поставить прокси, дающий доступ к /metrics kube-proxy:
```
$ kubectl apply -f kube-proxy-wrapper.yaml
```

Теперь можно поставить и оператор:

```
$ helm install --namespace prom --name prom stable/prometheus-operator -f values.yaml
```

## Получение доступа к Grafana

Получим информацию об IP-адресе, на котором развёрнута Grafana, и о пароле, созданном автоматически для администратора:
```
$ kubectl -n prom get service prom-grafana -o go-template='{{(index .status.loadBalancer.ingress 0).ip}}'
84.201.158.123

$ kubectl get secret prom-grafana -n prom -o go-template='{{ index .data "admin-password" | base64decode }}'
ailai9Eithaege4kaelo9beephee6bee
```

Подключаемся к http://84.201.158.123 и заходим под пользователем `admin` с паролём `ailai9Eithaege4kaelo9beephee6bee`

## Установка кеширующего прокси trickster

Для того, чтобы снизить нагрузку на prometheus и увеличить скорость отдачи данных, можно поставить кеширующий прокси trickter. В данном примере используется стандартная конфигурация, но в качестве URL prometheus'а используется http://prom-prometheus-operator-prometheus:9090 Кеш хранится в памяти, что позволяет обеспечить наивысшее быстродействие

При использовании multicluster-инсталяции лучше держать trickster в том кластере, что grafana, указывая при этом несколько origin'ов

Устанавливаем trickster, ставим его в тот же namespace, что и prometheus:

```
$ helm repo add tricksterproxy https://helm.tricksterproxy.io
$ helm install --namespace prom --name trickster tricksterproxy/trickster -f trickster.yaml
```

Теперь можно указать http://trickster:8480 в качестве data source в графане
