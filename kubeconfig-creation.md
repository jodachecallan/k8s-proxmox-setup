```
kubectl create serviceaccount adminuser

kubectl create clusterrolebinding adminuser-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=default:adminuser

apiVersion: v1
kind: Secret
metadata:
  name: adminuser-token
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: "adminuser"
type: kubernetes.io/service-account-token

kubectl get secret adminuser-token -n default -o jsonpath="{.data.token}" | base64 --decode

kubectl config view --raw -o jsonpath="{.clusters[0].cluster.certificate-authority-data}"

# kubeconfig-readonly.yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: <CA_DATA> 
    server: <K8S_API_SERVER_URL>            # URL of your Kubernetes API server
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: read-only-user
  name: read-only-context
current-context: read-only-context
users:
- name: read-only-user
  user:
    token: "<TOKEN>"
```