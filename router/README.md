# Роутер-модуль для Яндекс Облака

Данный модуль развёртывает инстанс, смотрящий в несколько сетей, настраивает интерфейсы и роутинг в указанные подсети. Внутри всех указанных сетей создаются специальные dmz-подсети, в которые уже и добавляется созданный инстанс

## Providers

| Name   | Version  |
|--------|----------|
| yandex | ~>0.35.0 |

## Inputs

| Name     | Description                             | Type   | Default       |
|----------|-----------------------------------------|--------|---------------|
| name     | имя инстанса                            | string |               |
| cidr     | /24 CIDR для DMZ-подсетей               | string |               |
| ssh-key  | ssh ключ для доступа                    | string |               |
| zone     | зона, в которой будет развёрнут инстанс | string | ru-central1-a |
| cores    | количество ядер в инстансе              | string | 2             |
| memory   | память инстанса, в ГБ                   | string | 4             |
| networks | список сетей, в которых должен быть развёрнут инстанс | <pre>list(object({&nbsp;network\_id    = string&nbsp;subnet\_cidr   = list(string)&nbsp;}))</pre> | |

## Outputs

| Name      | Description | Type           |
|-----------|-------------|----------------|
| address   |             | `list(string)` |

