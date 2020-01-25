# Używanie reguł Ingress – Ćwiczenia

Użyte deployments:

* [dumpster.yaml] (./dumpster.yaml)
* [echo.yaml] (./echo.yaml)
* [helloapp_multi.yaml] (./helloapp_multi.yaml)
* [helloapp_svc.yaml] (./helloapp_svc.yaml)

## Zainstaluj Ingress Controller na swoim klastrze i:

### Stwórz Ingress (i pomocnicze zasoby) jako default backend

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: ingress-default-backend
spec:
  backend:
    serviceName: dumpster-svc
    servicePort: 80
```

```bash
 (⎈ |minikube:default)]$ kubectl apply -f inress_backed.yaml
ingress.networking.k8s.io/ingress-default-backend created

(⎈ |minikube:default)]$ kubectl describe ingress ingress-default-backend

Name:             ingress-default-backend
Namespace:        default
Address:          192.168.99.111
Default backend:  dumpster-svc:80 (172.17.0.7:8080,172.17.0.8:8080)
Rules:
  Host  Path  Backends
  ----  ----  --------
  *     *     dumpster-svc:80 (172.17.0.7:8080,172.17.0.8:8080)
Annotations:
  kubectl.kubernetes.io/last-applied-configuration:  {"apiVersion":"networking.k8s.io/v1beta1","kind":"Ingress","metadata":{"annotations":{},"name":"ingress-default-backend","namespace":"default"},"spec":{"backend":{"serviceName":"dumpster-svc","servicePort":80}}}

Events:
  Type    Reason  Age   From                      Message
  ----    ------  ----  ----                      -------
  Normal  CREATE  34s   nginx-ingress-controller  Ingress default/ingress-default-backend
  Normal  UPDATE  32s   nginx-ingress-controller  Ingress default/ingress-default-backend
```

```bash
(⎈ |minikube:default)]$ curl 192.168.99.111 --no-progress-meter

v1 running on dumpster-dep-6f879dc97b-qjq5b

(⎈ |minikube:default)]$ curl 192.168.99.111 --no-progress-meter

v1 running on dumpster-dep-6f879dc97b-trcrk
```

### Stwórz Ingress (i pomocnicze zasoby) i ustaw fanout routing

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: ingress-fanout
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /v1
        backend:
          serviceName: helloapp-svc-svc
          servicePort: 80
      - path: /v2
        backend:
          serviceName: helloapp-multi-svc
          servicePort: 80
```

```bash
(⎈ |minikube:default)]$ kubectl apply -f ingress_fanout.yaml
ingress.networking.k8s.io/ingress-fanout created

(⎈ |minikube:default)]$ kubectl describe ingress ingress-fanout

Name:             ingress-fanout
Namespace:        default
Address:
Default backend:  default-http-backend:80 (<none>)
Rules:
  Host  Path  Backends
  ----  ----  --------
  *
        /v1   helloapp-svc-svc:80 (172.17.0.13:8080,172.17.0.14:8080)
        /v2   helloapp-multi-svc:80 (172.17.0.11:8080,172.17.0.12:8080)
Annotations:
  kubectl.kubernetes.io/last-applied-configuration:  {"apiVersion":"networking.k8s.io/v1beta1","kind":"Ingress","metadata":{"annotations":{"nginx.ingress.kubernetes.io/rewrite-target":"/"},"name":"ingress-fanout","namespace":"default"},"spec":{"rules":[{"http":{"paths":[{"backend":{"serviceName":"helloapp-svc-svc","servicePort":80},"path":"/v1"},{"backend":{"serviceName":"helloapp-multi-svc","servicePort":80},"path":"/v2"}]}}]}}

  nginx.ingress.kubernetes.io/rewrite-target:  /
Events:
  Type    Reason  Age   From                      Message
  ----    ------  ----  ----                      -------
  Normal  CREATE  5s    nginx-ingress-controller  Ingress default/ingress-fanout

(⎈ |minikube:default)]$ curl 192.168.99.111/v1 --no-progress-meter
Cześć, 🚢 =>  helloapp-svc-dep-75687db8f4-d8g44

(⎈ |minikube:default)]$ curl 192.168.99.111/v2 --no-progress-meter
Cześć, 🚢
```

### Stwórz Ingress (i pomocnicze zasoby) i ustaw host routing

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: ingress-virthost
spec:
  rules:
  - host: echo.192-168-99-111.nip.io
    http:
      paths:
      - backend:
          serviceName: echo-svc
          servicePort: 80
  - host: dump.192-168-99-111.nip.io
    http:
      paths:
      - backend:
          serviceName: dumpster-svc
          servicePort: 80
```

```bash
(⎈ |minikube:default)]$ kubectl apply -f ingress_virthost.yaml
ingress.networking.k8s.io/ingress-virthost created

(⎈ |minikube:default)]$ kubectl describe ingress ingress-virthost
Name:             ingress-virthost
Namespace:        default
Address:
Default backend:  default-http-backend:80 (<none>)
Rules:
  Host                        Path  Backends
  ----                        ----  --------
  echo.192-168-99-111.nip.io
                                 echo-svc:80 (172.17.0.10:8080,172.17.0.9:8080)
  dump.192-168-99-111.nip.io
                                 dumpster-svc:80 (172.17.0.7:8080,172.17.0.8:8080)
Annotations:
  kubectl.kubernetes.io/last-applied-configuration:  {"apiVersion":"networking.k8s.io/v1beta1","kind":"Ingress","metadata":{"annotations":{},"name":"ingress-virthost","namespace":"default"},"spec":{"rules":[{"host":"echo.192-168-99-111.nip.io","http":{"paths":[{"backend":{"serviceName":"echo-svc","servicePort":80}}]}},{"host":"dump.192-168-99-111.nip.io","http":{"paths":[{"backend":{"serviceName":"dumpster-svc","servicePort":80}}]}}]}}

Events:
  Type    Reason  Age   From                      Message
  ----    ------  ----  ----                      -------
  Normal  CREATE  5s    nginx-ingress-controller  Ingress default/ingress-virthost

(⎈ |minikube:default)]$ curl echo.192-168-99-111.nip.io --no-progress-meter
CLIENT VALUES:
client_address=172.17.0.4
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://echo.192-168-99-111.nip.io:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
accept=*/*
host=echo.192-168-99-111.nip.io
user-agent=curl/7.67.0
x-forwarded-for=192.168.99.1
x-forwarded-host=echo.192-168-99-111.nip.io
x-forwarded-port=80
x-forwarded-proto=http
x-real-ip=192.168.99.1
x-request-id=86c679e2ed9146d6aef80f65a0b46abb
x-scheme=http
BODY:
    
(⎈ |minikube:default)]$ curl dump.192-168-99-111.nip.io --no-progress-meter
v1 running on dumpster-dep-6f879dc97b-qjq5b
```

### Stwórz Ingress (i pomocnicze zasoby) i wymieszaj dowolnie fanout i host routing

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: ingress-mix
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$1
spec:
  rules:
  - host: app.192-168-99-111.nip.io
    http:
      paths:
      - backend:
          serviceName: helloapp-multi-svc
          servicePort: 80
  - host: mix.192-168-99-111.nip.io
    http:
      paths:
      - path: /echo/?(.*)
        backend:
          serviceName: echo-svc
          servicePort: 80
      - path: /app
        backend:
          serviceName: helloapp-svc-svc
          servicePort: 80
      - backend:
          serviceName: dumpster-svc
          servicePort: 80
```

```bash
(⎈ |minikube:default)]$ kubectl apply -f ingress_mix.yaml
ingress.networking.k8s.io/ingress-mix created

(⎈ |minikube:default)]$  kubectl describe ing ingress-mix
Name:             ingress-mix
Namespace:        default
Address:
Default backend:  default-http-backend:80 (<none>)
Rules:
  Host                       Path  Backends
  ----                       ----  --------
  app.192-168-99-111.nip.io
                                helloapp-multi-svc:80 (172.17.0.11:8080,172.17.0.12:8080)
  mix.192-168-99-111.nip.io
                             /echo/?(.*)   echo-svc:80 (172.17.0.10:8080,172.17.0.9:8080)
                             /app          helloapp-svc-svc:80 (172.17.0.13:8080,172.17.0.14:8080)
                                           dumpster-svc:80 (172.17.0.7:8080,172.17.0.8:8080)
Annotations:
  kubectl.kubernetes.io/last-applied-configuration:  {"apiVersion":"networking.k8s.io/v1beta1","kind":"Ingress","metadata":{"annotations":{"nginx.ingress.kubernetes.io/rewrite-target":"/$1"},"name":"ingress-mix","namespace":"default"},"spec":{"rules":[{"host":"app.192-168-99-111.nip.io","http":{"paths":[{"backend":{"serviceName":"helloapp-multi-svc","servicePort":80}}]}},{"host":"mix.192-168-99-111.nip.io","http":{"paths":[{"backend":{"serviceName":"echo-svc","servicePort":80},"path":"/echo/?(.*)"},{"backend":{"serviceName":"helloapp-svc-svc","servicePort":80},"path":"/app"},{"backend":{"serviceName":"dumpster-svc","servicePort":80}}]}}]}}

  nginx.ingress.kubernetes.io/rewrite-target:  /$1
Events:
  Type    Reason  Age   From                      Message
  ----    ------  ----  ----                      -------
  Normal  CREATE  6s    nginx-ingress-controller  Ingress default/ingress-mix

(⎈ |minikube:default)]$ curl app.192-168-99-111.nip.io --no-progress-meter
Cześć, 🚢

(⎈ |minikube:default)]$ curl mix.192-168-99-111.nip.io/ --no-progress-meter
v1 running on dumpster-dep-6f879dc97b-trcrk

(⎈ |minikube:default)]$ curl mix.192-168-99-111.nip.io/app --no-progress-meter
Cześć, 🚢 =>  helloapp-svc-dep-75687db8f4-v7ltk

(⎈ |minikube:default)]$ curl mix.192-168-99-111.nip.io/app/1/ --no-progress-meter
Cześć, 🚢 =>  helloapp-svc-dep-75687db8f4-d8g44

(⎈ |minikube:default)]$ curl mix.192-168-99-111.nip.io/echo --no-progress-meter
CLIENT VALUES:
client_address=172.17.0.4
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://mix.192-168-99-111.nip.io:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
accept=*/*
host=mix.192-168-99-111.nip.io
user-agent=curl/7.67.0
x-forwarded-for=192.168.99.1
x-forwarded-host=mix.192-168-99-111.nip.io
x-forwarded-port=80
x-forwarded-proto=http
x-real-ip=192.168.99.1
x-request-id=23c80827c009799093993d60e014150b
x-scheme=http
BODY:
-no body in request-

(⎈ |minikube:default)]$ curl mix.192-168-99-111.nip.io/echo/123 --no-progress-meter
CLIENT VALUES:
client_address=172.17.0.4
command=GET
real path=/123
query=nil
request_version=1.1
request_uri=http://mix.192-168-99-111.nip.io:8080/123
(...)
```

Wnioski: Brak użycia w ingress `?(.*)` powoduje, że zapytanie jest "skracane" do zadeklarowanej postacji. \n
Użycie w/w powoduje, że to co po zadeklarownym `path` się znajduje również trafia do poda i w przypadku braku takiej podstrony mamy 404.

### Pobaw się regex – może jest lepsza i wydajniejsza forma przechwytywania ścieżki?
