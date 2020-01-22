# Wdrożenie Ingress Controller – Ćwiczenia

**Zainstaluj na swoim lokalnym środowisku NGINX Ingress Controller, korzystając z prostej konfiguracji.**

Zgodnie z https://github.com/kubernetes/ingress-nginx/blob/master/docs/deploy/index.md#minikube

Konfiguracja podstawowych deployment i service standardowo odbywa się przez polecenie

```bash
(⎈ |minikube:default)]$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.27.1/deploy/static/mandatory.yaml

(⎈ |minikube:default)]$ kubectl get all -n ingress-nginx

NAME                                           READY   STATUS    RESTARTS   AGE
pod/nginx-ingress-controller-948ffd8cc-j8z4r   1/1     Running   0          27s

NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-ingress-controller   1/1     1            1           27s

NAME                                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-ingress-controller-948ffd8cc   1         1         1       27s
```

ale w zainstalowanym minikube-1.5.2 ingres wystarczy włączyć poleceniem, a potrzebne obiekty już istnieją:

```bash
(⎈ |minikube:default)]$ minikube addons enable ingress

(⎈ |minikube:default)]$ kubectl get all -n kube-system
NAME                                            READY   STATUS    RESTARTS   AGE
pod/coredns-5644d7b6d9-7r7fj                    1/1     Running   0          10m
pod/coredns-5644d7b6d9-ssx8j                    1/1     Running   0          10m
pod/etcd-minikube                               1/1     Running   0          9m54s
pod/kube-addon-manager-minikube                 1/1     Running   0          10m
pod/kube-apiserver-minikube                     1/1     Running   0          10m
pod/kube-controller-manager-minikube            1/1     Running   0          9m44s
pod/kube-proxy-twm9c                            1/1     Running   0          10m
pod/kube-scheduler-minikube                     1/1     Running   0          9m43s
pod/nginx-ingress-controller-6fc5bcc8c9-n9gp7   1/1     Running   0          10m
pod/storage-provisioner                         1/1     Running   0          10m

NAME               TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
service/kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   11m

NAME                        DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                 AGE
daemonset.apps/kube-proxy   1         1         1       1            1           beta.kubernetes.io/os=linux   11m

NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/coredns                    2/2     2            2           11m
deployment.apps/nginx-ingress-controller   1/1     1            1           10m

NAME                                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/coredns-5644d7b6d9                    2         2         2       10m
replicaset.apps/nginx-ingress-controller-6fc5bcc8c9   1         1         1       10m
```

Dalsza część zrobiona na podstawie:
* https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/
* https://minikube.sigs.k8s.io/docs/tutorials/nginx_tcp_udp_ingress/

### Tworzymy deployment i service pk

```bash
(⎈ |minikube:default)]$ kubectl apply -f ingress-test.yaml

(⎈ |minikube:default)]$ kubectl get all

kubectl get all
NAME                      READY   STATUS    RESTARTS   AGE
pod/pk-57dcbbff5c-8fbcj   1/1     Running   0          2m16s

NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP   22h
service/pk           ClusterIP   10.107.170.96   <none>        80/TCP    2m16s

NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/pk   1/1     1            1           2m16s

NAME                            DESIRED   CURRENT   READY   AGE
replicaset.apps/pk-57dcbbff5c   1         1         1       2m16s
```

### Zgodnie z opisem w linku powyżej dodajemy do configmap dla TCP informacje o service dla deploymentu.

```bash
(⎈ |minikube:default)]$ kubectl patch configmap tcp-services -n kube-system --patch '{"data":{"80":"default/pk:80"}}'
configmap/tcp-services patched

(⎈ |minikube:default)]$ kubectl get configmap tcp-services -n kube-system -o yaml
apiVersion: v1
data:
  "80": default/pk:80
kind: ConfigMap
metadata:
  creationTimestamp: "2020-01-21T21:40:39Z"
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
  name: tcp-services
  namespace: kube-system
  resourceVersion: "5915"
  selfLink: /api/v1/namespaces/kube-system/configmaps/tcp-services
  uid: 0599685b-58ab-40ad-a2b5-510102f436c3
```

### Tworzymy ingress dla deploymentu

```bash
(⎈ |minikube:default)]$ kubectl apply -f ingress-test-ingress.yaml

(⎈ |minikube:default)]$ kubectl get ingress

NAME              HOSTS   ADDRESS   PORTS   AGE
ingress-test-pk   pk      192.168.99.109   80      2m15s

```

Aby sprawdzić działanie dodajemy nazwę ip 192.168.99.109 z nazwą pk do `hosts`
