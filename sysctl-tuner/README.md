# sysctl-tuner

## Установка sysctl-tuner'а

systctl-tuner -- оператор для установки определённых sysctl на ноды. Для его установки в ваш managed кластер в Yandex.Cloud нужно аутентифицироваться в container registry [согласно инструкции](https://cloud.yandex.ru/docs/container-registry/operations/authentication), а затем выполнить `./deploy.sh`. Этот скрипт совершает следующие действия:
1. Создаёт registry для docker образа с аддоном
2. Собирает образ и пушит его в registry
3. Создаёт service-account, namespaces и pod для самого оператора. Кроме того инициализирует ConfigMap, в котором устанавливает `sysctl net.ipv4.tcp_timestamps=0`

Обратите внимание, что для корректной работы оператора в кластере должен быть настроен SA, который имеет право пуллить с registry, находящихся в этом фолдере.

## Изменение настроек tuner'а

Для того, чтобы прописать новые sysctl'и достаточно отредактировать ConfigMap и прописать туда нужные sysctl и их значения в поле sysctlTuner:

```
$ kubectl edit -n sysctl-tuner ConfigMap addon-operator
$ kubectl describe -n sysctl-tuner ConfigMap addon-operator
...
sysctlTuner:
----
params:
  net.ipv4.tcp_timestamps: "0"
  net.core.somaxconn: "1024"
sleep: "300"

```

## Удаление оператора

Для удаления оператора достаточно запустить `./undeploy.sh`, это удалит registry (если в нём нет сторонних image'ей) и все компоненты оператора
