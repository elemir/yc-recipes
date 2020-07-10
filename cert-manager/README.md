# Установка сертификатов ingress-nginx

Данная инструкция -- пример установки ingress-nginx и настройки двух ingress'ов, закрытых https. Для части доменов сертификат автоматически генерируется cert-manager'ом, а для части используется заранее полученный сертификат. Этот подход позволяет покупать сертификаты только на самые важные домены, а для остальных использовать Lets Encrypt.

1. Положите файлы с вашим заранее полученным сертификатом и его ключом в данную папку

```
$ ls tls.*
tls.key tls.crt
```

2. Создайте секрет с сертификатом и ключом:
```
$ kubectl create secret tls predefined-cert --key tls.key --cert tls.crt
```

3. Правим issuer.yaml и ставим туда ваш email:
```
$ cat issuer.yaml
---
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your@mail.com
    privateKeySecretRef:
      name: letsencrypt-secret
    solvers:
    - http01:
        ingress:
          class: nginx

```

4. Исправляем app.yaml и ставим туда ваш домен:
```
$ cat app.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  tls:
    - hosts:
      - yourdomain.com
      secretName: predefined-cert
  rules:
    - host: yourdomain.com
      http:
        paths:
        - backend:
            serviceName: app
            servicePort: 80
          path: /
...

```

4. Устанавливаем ingress-controller, cert-manager и необходимые ресурсы:
```
$ ./install.sh
```
