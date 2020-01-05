# Ćwiczenie 1

Korzystając z wiedzy z lekcji przetestuj następujące scenariusze komunikacji:

* container-to-container w Pod. Wykorzystaj do tego nginx.

```bash
kubectl create -f container2container.yaml

winpty kubectl exec -it container2container -c tools sh

/ $ curl localhost
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
```

* Komunikacja pomiędzy Podami – Pod-to-Pod. Wykorzystaj do tego nginx.

```bash
kubectl create -f pod2pod.yaml

kubectl get pods -o wide

NAME            READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
pod2pod-nginx   1/1     Running   0          78s   172.17.0.6   minikube   <none>           <none>
pod2pod-tools   1/1     Running   0          78s   172.17.0.7   minikube   <none>           <none>
```

```bash
 winpty kubectl exec -it pod2pod-tools sh
/ $ curl 172.17.0.6

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
```

* Wykorzystaj nginx i wystaw go za pomocą serwisu ClusterIP w środku klastra.

```bash
kubectl create -f nginx_clusterIP.yaml

kubectl get svc
NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
cluster-ip-nginx   ClusterIP   10.100.61.101   <none>        80/TCP    9m54s
kubernetes         ClusterIP   10.96.0.1       <none>        443/TCP   31d
```

```bash
winpty kubectl exec -it pod2pod-tools sh

/ $ curl 10.100.61.101
Hello from nginx1
/ $ curl 10.100.61.101
Hello from nginx2
/ $ curl cluster-ip-nginx
Hello from nginx2
/ $ curl cluster-ip-nginx
Hello from nginx1
```

* Wykorzystaj nginx i wystaw go na świat za pomocą serwisu NodePort w dwóch opcjach: bez wskazywania portu dla NodePort i ze wskazaniem.

```bash
kubectl create -f nginx_nodePort.yaml

kubectl get svc
NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes        ClusterIP   10.96.0.1       <none>        443/TCP        31d
node-nginx        NodePort    10.106.230.53   <none>        80:30026/TCP   44s
node-port-nginx   NodePort    10.111.123.21   <none>        80:32000/TCP   44s

kubectl get pods
NAME            READY   STATUS    RESTARTS   AGE
nginx1          1/1     Running   0          65s
nginx2          1/1     Running   0          65s
```

Do sprawdzenia trzeba użyć adresu virtualki minikube

```bash
(⎈ |minikube:default)]$ curl -s http://192.168.99.103:32000/
Hello from nginx1
(⎈ |minikube:default)]$ curl -s http://192.168.99.103:32000/
Hello from nginx2
(⎈ |minikube:default)]$ curl -s http://192.168.99.103:30026/
Hello from nginx1
(⎈ |minikube:default)]$ curl -s http://192.168.99.103:30026/
Hello from nginx2
```

* Wykorzystaj nginx i wystaw go na świat za pomocą serwisu typu LoadBalancer.

```bash
 kubectl create -f nginx_loadbalancer.yaml

kubectl get pods

NAME     READY   STATUS    RESTARTS   AGE
nginx1   1/1     Running   0          66s
nginx2   1/1     Running   0          66s

kubectl get svc

NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes             ClusterIP      10.96.0.1       <none>        443/TCP          31d
loadbalancer-service   LoadBalancer   10.98.111.149   <pending>     8080:30380/TCP   32s
```

```bash
minikube service loadbalancer-service
|-----------|----------------------|-------------|-----------------------------|
| NAMESPACE |         NAME         | TARGET PORT |             URL             |
|-----------|----------------------|-------------|-----------------------------|
| default   | loadbalancer-service |             | http://192.168.99.103:30380 |
|-----------|----------------------|-------------|-----------------------------|
* Opening service default/loadbalancer-service in default browser...
```

Minikube nie przydziela EXTERNAL-IP tak poprostu, więc sprawdzone w przeglądarce, że działa po IP wirtualki oraz curl

```bash
(⎈ |minikube:default)]$ curl -s http://192.168.99.103:30380
Hello from nginx2
(⎈ |minikube:default)]$ curl -s http://192.168.99.103:30380
Hello from nginx1
```

# Ćwiczenie 2

* Utwórz dwa Pody z aplikacją helloapp, które mają po jednym wspólnym Label, oraz posiadają oprócz tego inne Label (poniżej przykład).

```yaml
# Pod 1
labels:
  app: helloapp
  ver: v1

# Pod 2
labels:
  app: helloapp
  ver: v1
```

```bash
kubectl create -f helloapp_multilabel.yaml

kubectl get pods --show-labels

NAME           READY   STATUS    RESTARTS   AGE   LABELS
multilabels1   1/1     Running   0          68s   app=helloapp,instance=one
multilabels2   1/1     Running   0          68s   app=helloapp,instance=two

kubectl get svc

NAME               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
kubernetes         ClusterIP   10.96.0.1        <none>        443/TCP          31d
node-multilabels   NodePort    10.104.233.121   <none>        8080:30348/TCP   114s
```

* Do tak utworzonych Podów podepnij serwis i sprawdź jak się zachowuje.

```bash
(⎈ |minikube:default)]$ kubectl get endpoints

NAME               ENDPOINTS                         AGE
kubernetes         192.168.99.103:8443               31d
node-multilabels   172.17.0.3:8080,172.17.0.5:8080   6m40s
```

```bash
(⎈ |minikube:default)]$ curl -s http://192.168.99.103:30348
Cześć, 🚢 =>  multilabels2
(⎈ |minikube:default)]$ curl -s http://192.168.99.103:30348
Cześć, 🚢 =>  multilabels2
(⎈ |minikube:default)]$ curl -s http://192.168.99.103:30348
Cześć, 🚢 =>  multilabels1
```

Pomimo dodatkowych etykiet ruch kierowany jest zgodnie z selektorem.
Wniosek: Ilość etykiet nie wpływa na service.
