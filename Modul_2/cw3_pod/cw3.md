# Celem ćwiczeń jest utrwalenie komend z dem

* Stwórz Pod na bazie obrazu z modułu 1
  * Zobacz w jakim stanie on się znajduje
  * Podejrzyj jego logi
  * Wykonaj w koneterze wylistowanie katalogów
  * Odpytaj się http://localhost:PORT w koneterze
  * Zrób to samo z powołanego osobno poda (kubectl run)
  * Dostań się do poda za pomocą przekierowania portów
  * Dostań się do poda za pomocą API Server
* Stwórz Pod zawierający dwa kontenery – busybox i poznajkubernetes/helloapp:multi
  * Zweryfikuj, że Pod działa poprawnie
  * Jak nie działa, dowiedz się dlaczego
  * Zastanów się nad rozwiązaniem problemu jeżeli istnieje – co można by było zrobić i jak


### Stworzenine pod na bazie obrazu z modułu 1

```bash
kubectl create -f helloapp.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
 name: helloapp
spec:
 containers:
 - image: poznajk8s/helloapp:build
   name: helloapp
```

##### Zobacz w jakim stanie on się znajduje

```bash
kubectl get pod helloapp
```

```bash
NAME       READY   STATUS              RESTARTS   AGE
helloapp   0/1     ContainerCreating   0          2m20s
helloapp   1/1     Running             0          3m16s
```

##### Podejrzyj jego logi

```bash
kubectl logs helloapp
```

```bash
server started
```

##### Wykonaj w koneterze wylistowanie katalogów

```bash
kubectl.exe exec -it helloapp ls
```

```bash
Dockerfile  go.mod  main  main.go
```

##### Odpytaj się http://localhost:PORT w koneterze

```bash
kubectl exec helloapp -- wget -qO- localhost:8080
```

```bash
Cześć, ??
```

##### Zrób to samo z powołanego osobno poda (kubectl run)

```bash
kubectl describe pod helloapp | grep IP:

kubectl run bb --image=busybox --restart=Never --rm -it -- sh

wget -qO- 172.17.0.4:8080
```

##### Dostań się do poda za pomocą przekierowania portów

```bash
kubectl port-forward helloapp 8080:8080
```

##### Dostań się do poda za pomocą API Server

```bash
kubectl proxy
```

wejdź na stronę http://127.0.0.1:8001/api/v1/namespaces/default/pods/http:helloapp:8080/proxy/

### Stwórz Pod zawierający dwa kontenery – busybox i poznajkubernetes/helloapp:multi

##### Zweryfikuj, że Pod działa poprawnie

##### Jak nie działa, dowiedz się dlaczego

##### Zastanów się nad rozwiązaniem problemu jeżeli istnieje – co można by było zrobić i jak
