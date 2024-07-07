from a new cluster to install kafka:


- Install Argo
```
kubectl create namespace argocd                                                                    
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
- Expose Argo

```
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}' 
```

- Get Argo password

```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

at this point you can log in using admin username and password above


run helm against repo:

```
kubectl create namespace confluent
kubectl config set-context --current --namespace confluent
helm repo add confluentinc https://packages.confluent.io/helm  in confluent                                 
helm repo update -n confluent
helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes -n confluent
```

create Argo application:

kubectl apply -f kafka-application.yaml
