# Service Discovery – Ćwiczenia

Przetestuj działanie Service Discovery korzystając ze swojej aplikacji albo helloapp.

### Utwórz dwa namespaces. W każdym namespaces umieć pod i serwis

Namespace default jest domyślnym, więc nie trzeba go tworzyć.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: demo
  labels:
    ns: demo
---
apiVersion: v1
kind: Pod
metadata:
  name: helloapp
  namespace: default
  labels:
    ns: default
spec:
  containers:
  - name: multilabels1e1
    image: poznajkubernetes/helloapp:svc
    resources:
      limits:
        memory: "128Mi"
        cpu: "500m"
    ports:
    - containerPort: 8080
      name: http
      protocol: TCP
---
apiVersion: v1
kind: Pod
metadata:
  name: helloapp
  namespace: demo
  labels:
    ns: demo
spec:
  containers:
  - name: multilabels2
    image: poznajkubernetes/helloapp:svc
    resources:
      limits:
        memory: "128Mi"
        cpu: "500m"
    ports:
    - containerPort: 8080
      name: http
      protocol: TCP
---
apiVersion: v1
kind: Service
metadata:
  name: helloapp
  namespace: default
spec:
  type: ClusterIP
  selector:
    ns: default
  ports:
  - port: 8080
    name: http
---
apiVersion: v1
kind: Service
metadata:
  name: helloapp
  namespace: demo
spec:
  type: ClusterIP
  selector:
    ns: demo
  ports:
  - port: 8080
    name: http
```


```bash
(⎈ |minikube:default)]$ kubectl.exe create -f helloapp_multilNS.yaml

(⎈ |minikube:default)]$  kubectl get svc

NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
helloapp     ClusterIP   10.105.191.53   <none>        8080/TCP   9m31s
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP    31d

(⎈ |minikube:default)]$ kubectl get svc --namespace=demo

NAME       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
helloapp   ClusterIP   10.103.96.243   <none>        8080/TCP   9m59s

(⎈ |minikube:default)]$ kubectl get pods -o wide

NAME       READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
helloapp   1/1     Running   0          10m   172.17.0.6   minikube   <none>           <none>

(⎈ |minikube:default)]$ kubectl get pods -o wide --namespace=demo

NAME       READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
helloapp   1/1     Running   0          11m   172.17.0.7   minikube   <none>           <none>
```

### Przetestuj działanie Service Discovery z wykorzystaniem curl i nslookup. Jeśli używasz swojej aplikacji wywołaj endpointy pomiędzy aplikacjami

* Sprawdzenie z namespace default

```bash
(⎈ |minikube:default)]$ winpty kubectl run -it --rm tools --generator=run-pod/v1 --image=giantswarm/tiny-tools
If you dont see a command prompt, try pressing enter.
/ $ nslookup helloapp
Server:         10.96.0.10
Address:        10.96.0.10#53

Name:   helloapp.default.svc.cluster.local
Address: 10.105.191.53

/ $ nslookup helloapp.demo
Server:         10.96.0.10
Address:        10.96.0.10#53

Name:   helloapp.demo.svc.cluster.local
Address: 10.103.96.243

/ $ curl helloapp:8080
Cze,  =>  helloapp
/ $ curl helloapp.demo:8080
Cze,  =>  helloapp
```

* Sprawdzenie z namespace demo

```bash
(⎈ |minikube:default)]$ winpty kubectl run -it --rm tools --generator=run-pod/v1 --image=giantswarm/tiny-tools -n demo
If you dont see a command prompt, try pressing enter.
/ $ nslookup helloapp
Server:         10.96.0.10
Address:        10.96.0.10#53

Name:   helloapp.demo.svc.cluster.local
Address: 10.103.96.243

/ $ nslookup helloapp.default
Server:         10.96.0.10
Address:        10.96.0.10#53

Name:   helloapp.default.svc.cluster.local
Address: 10.105.191.53

/ $ curl helloapp:8080
Cze,  =>  helloapp
/ $ curl helloapp.default:8080
Cze,  =>  helloapp
```
