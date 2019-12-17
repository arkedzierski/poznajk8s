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

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: 2containers
  labels:
    name: 2containers
spec:
  containers:
  - name: busybox
    image: busybox
    resources:
      limits:
        memory: "128Mi"
        cpu: "500m"

  - name: helloapp
    image: poznajkubernetes/helloapp:multi
    resources:
      limits:
        memory: "128Mi"
        cpu: "500m"
```

##### Zweryfikuj, że Pod działa poprawnie
```bash
kubectl.exe get pod 2containers
```

```bash
NAME         READY   STATUS             RESTARTS   AGE
2containers   1/2     CrashLoopBackOff   5          4m13s
```

##### Jak nie działa, dowiedz się dlaczego
```bash
kubectl.exe describe pod 2containers

  busybox:
    Container ID:   docker://d8acdbd991c6457d9e23fb942c6bc4c06015a6e2e25bed68718efb507eb5780a
    Image:          busybox
    Image ID:       docker-pullable://busybox@sha256:1828edd60c5efd34b2bf5dd3282ec0cc04d47b2ff9caa0b6d4f07a21d1c08084
    Port:           <none>
    Host Port:      <none>
    State:          Waiting
      Reason:       CrashLoopBackOff
    Last State:     Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Tue, 17 Dec 2019 22:11:02 +0100
      Finished:     Tue, 17 Dec 2019 22:11:02 +0100
    Ready:          False
    Restart Count:  2
(...)
 helloapp:
    Container ID:   docker://acc144edcc3fd8626a645d03b0d86e915baf5367624d88e610bdfed005790850
    Image:          poznajkubernetes/helloapp:multi
    Image ID:       docker-pullable://poznajkubernetes/helloapp@sha256:6bae4ef606a02436aa94e5eb9dfb62e943f6a152cfabbafb7c61508b1c48e222
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Tue, 17 Dec 2019 22:10:40 +0100
    Ready:          True
    Restart Count:  0
(...)
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  <unknown>          default-scheduler  Successfully assigned default/2containers to minikube
  Normal   Pulling    53s                kubelet, minikube  Pulling image "poznajkubernetes/helloapp:multi"
  Normal   Created    43s                kubelet, minikube  Created container helloapp
  Normal   Pulled     43s                kubelet, minikube  Successfully pulled image "poznajkubernetes/helloapp:multi"
  Normal   Started    42s                kubelet, minikube  Started container helloapp
  Normal   Pulling    26s (x3 over 57s)  kubelet, minikube  Pulling image "busybox"
  Normal   Created    20s (x3 over 53s)  kubelet, minikube  Created container busybox
  Normal   Started    20s (x3 over 53s)  kubelet, minikube  Started container busybox
  Normal   Pulled     20s (x3 over 53s)  kubelet, minikube  Successfully pulled image "busybox"
  Warning  BackOff    7s (x4 over 38s)   kubelet, minikube  Back-off restarting failed container
```

```bash
kubectl.exe logs 2containers -c helloapp
server started
```

```bash
kubectl.exe logs 2containers -c busybox

```

```bash
kubectl.exe get pod 2containers -o yaml

containers:
  - image: busybox
    imagePullPolicy: Always
    name: busybox
(...)
  - image: poznajkubernetes/helloapp:multi
    imagePullPolicy: IfNotPresent
    name: helloapp
(...)
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2019-12-17T21:10:24Z"
    status: "True"
    type: Initialized
  - lastProbeTime: null
    lastTransitionTime: "2019-12-17T21:10:24Z"
    message: 'containers with unready status: [busybox]'
    reason: ContainersNotReady
    status: "False"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: "2019-12-17T21:10:24Z"
    message: 'containers with unready status: [busybox]'
    reason: ContainersNotReady
    status: "False"
    type: ContainersReady
  - lastProbeTime: null
    lastTransitionTime: "2019-12-17T21:10:24Z"
    status: "True"
    type: PodScheduled
  containerStatuses:
  - containerID: docker://f64638912eba8f764bcdf589925bf44e46fc548289c7523a94be31492178c970
    image: busybox:1
    imageID: docker-pullable://busybox@sha256:1828edd60c5efd34b2bf5dd3282ec0cc04d47b2ff9caa0b6d4f07a21d1c08084
    lastState:
      terminated:
        containerID: docker://f64638912eba8f764bcdf589925bf44e46fc548289c7523a94be31492178c970
        exitCode: 0
        finishedAt: "2019-12-17T21:16:49Z"
        reason: Completed
        startedAt: "2019-12-17T21:16:49Z"
    name: busybox
    ready: false
    restartCount: 6
    started: false
    state:
      waiting:
        message: back-off 5m0s restarting failed container=busybox pod=2containers_default(596b5827-2037-4455-8b0b-3da15322a70a)
        reason: CrashLoopBackOff
```

##### Zastanów się nad rozwiązaniem problemu jeżeli istnieje – co można by było zrobić i jak
* zmienić command w kontenerze busybox aby kontener nie konczył od razu swojej pracy i pracował "ciągle"
* jeżeli kontener busybox ma zrobić zadanie i się zakończyć to przenieść go do initContainers
* ustawić restartPolicy na OnFailure co spowoduje:

```bash
kubectl get pod -w
NAME             READY   STATUS    RESTARTS   AGE
2containers      0/2     Pending   0          0s
2containers      0/2     Pending   0          0s
2containers      0/2     ContainerCreating   0          0s
2containers      1/2     Running             0          6s
```
