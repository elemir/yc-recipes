helm install --name ingress stable/nginx-ingress --values values.yaml
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.2/cert-manager.yaml
echo "Waiting for cert-manager"
sleep 30
kubectl apply -f app.yaml
kubectl apply -f issuer.yaml
