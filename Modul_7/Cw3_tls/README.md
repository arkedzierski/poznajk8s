# Używanie certyfikatów w Ingress – Ćwiczenia

## Korzystając z Ingress utworzonych przy okazji „Używanie reguł Ingress – Ćwiczenia” zmodyfikuje je o wykorzystanie certyfikatów

*W zależności od możliwości użyj self-sign lub Let’s Encrypt.*

Instalacja cert-manager:

```bash
(⎈ |minikube:default)]$ kubectl create namespace cert-manager

(⎈ |minikube:default)]$ kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.13.0/cert-manager.yaml
```

weryfikacja instalacji:

```bash
(⎈ |minikube:default)]$ kubectl get pods --namespace cert-manager

NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-6f578f4565-x628f              1/1     Running   0          66s
cert-manager-cainjector-75b6bc7b8b-rft6l   1/1     Running   0          66s
cert-manager-webhook-8444c4bc77-xrzm4      1/1     Running   0          66s
```

tworzymy issuer:

```bash
(⎈ |minikube:default)]$ kubectl apply -f self_issuer.yaml

issuer.cert-manager.io/selfsigning-issuer created
```

oraz deployment z ingress:

```bash
(⎈ |minikube:default)]$ kubectl apply -f ingress_tls.yaml

service/dumpster-tls created
deployment.apps/dumpster created
service/helloapp-multi-svc created
deployment.apps/helloapp-multi-dep created
ingress.networking.k8s.io/ingress-tls created
```

Issuer sam tworzy certyfikat:
```bash
 (⎈ |minikube:default)]$ kubectl describe secret tls-self-issuer
Name:         tls-self-issuer
Namespace:    default
Labels:       <none>
Annotations:  cert-manager.io/alt-names: dump.192-168-99-111.nip.io
              cert-manager.io/certificate-name: tls-self-issuer
              cert-manager.io/common-name:
              cert-manager.io/ip-sans:
              cert-manager.io/issuer-kind: Issuer
              cert-manager.io/issuer-name: selfsigning-issuer
              cert-manager.io/uri-sans:

Type:  kubernetes.io/tls

Data
====
ca.crt:   1127 bytes
tls.crt:  1127 bytes
tls.key:  1679 bytes
```

sprawdzamy, że certyfikat działa dla właściwego hosta:

```bash
(⎈ |minikube:default)]$ curl --insecure -v https://dump.192-168-99-111.nip.io/ 2>&1 | awk 'BEGIN { cert=0 } /^\* SSL connection/ { cert=1 } /^\*/ { if (cert) print }'

* SSL connection using TLSv1.2 / ECDHE-RSA-AES256-GCM-SHA384
* ALPN, server accepted to use h2
* Server certificate:
*  subject: O=cert-manager
*  start date: Jan 25 20:29:59 2020 GMT
*  expire date: Apr 24 20:29:59 2020 GMT
*  issuer: O=cert-manager
*  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x688c10)
* Connection state changed (MAX_CONCURRENT_STREAMS == 128)!
* Connection #0 to host dump.192-168-99-111.nip.io left intact

(⎈ |minikube:default)]$ curl --insecure -v https://app.192-168-99-111.nip.io/ 2>&1 | awk 'BEGIN { cert=0 } /^\* SSL connection/ { cert=1 } /^\*/ { if (cert) print }'
* SSL connection using TLSv1.2 / ECDHE-RSA-AES256-GCM-SHA384
* ALPN, server accepted to use h2
* Server certificate:
*  subject: O=Acme Co; CN=Kubernetes Ingress Controller Fake Certificate
*  start date: Jan 25 13:40:13 2020 GMT
*  expire date: Jan 24 13:40:13 2021 GMT
*  issuer: O=Acme Co; CN=Kubernetes Ingress Controller Fake Certificate
*  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x328c10)
* Connection state changed (MAX_CONCURRENT_STREAMS == 128)!
* Connection #0 to host app.192-168-99-111.nip.io left intact
```
