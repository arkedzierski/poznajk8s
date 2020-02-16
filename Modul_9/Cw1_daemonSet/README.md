# Tworzenie klastra z 3 node na GKE

https://kubernetes.io/docs/reference/kubectl/cheatsheet/ - przydatny link z cheatsheet dotyczące config i context

https://cloud.google.com/sdk/docs/downloads-docker - Uruchomienie Google Cloud SDK w Docker

https://hub.docker.com/r/google/cloud-sdk/ - pobranie image z DockerHub

https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters - utworzenie prywatnego klastra

`docker-machine start/stop` - uruchamianie/zatrzymywanie dockera
`docker pull gcr.io/google.com/cloudsdktool/cloud-sdk:latest` - pobranie pełnego ostatniego image (ok 690 MB)
`docker pull gcr.io/google.com/cloudsdktool/cloud-sdk:slim` - pobranie wersji slim (ok 340 MB)
`docker pull gcr.io/google.com/cloudsdktool/cloud-sdk:alpine` - pobieranie wersji maksymalnie odchudzonej (ok 100 MB)

Weryfikaja poprawności instalacji:

```bash
(⎈ |N/A:default)]$ docker run gcr.io/google.com/cloudsdktool/cloud-sdk:slim gcloud version

Google Cloud SDK 278.0.0
alpha 2020.01.24
beta 2020.01.24
bq 2.0.52
core 2020.01.24
gsutil 4.47
kubectl 2020.01.24
```

Autoryzacja:

```bash
(⎈ |N/A:default)]$ winpty docker run -ti --name gcloud-config gcr.io/google.com/cloudsdktool/cloud-sdk:slim gcloud auth login
```

Sprawdzenie poprawności:

```bash
docker run --rm --volumes-from gcloud-config gcr.io/google.com/cloudsdktool/cloud-sdk:slim gcloud compute instances list --project poznajk8s

NAME                                                ZONE           MACHINE_TYPE   PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP  STATUS
gke-poznajk8s-cluster-1-default-pool-f04ec751-4zw1  us-central1-a  n1-standard-1               10.128.0.2                RUNNING
gke-poznajk8s-cluster-1-default-pool-f04ec751-nrhv  us-central1-a  n1-standard-1               10.128.0.3                RUNNING
gke-poznajk8s-cluster-1-default-pool-f04ec751-p86q  us-central1-a  n1-standard-1               10.128.0.4                RUNNING
```

Przejście do shell obrazu:

```bash
(⎈ |N/A:default)]$ winpty docker run --rm -it --volumes-from gcloud-config gcr.io/google.com/cloudsdktool/cloud-sdk:slim
```

instalacja kubectl:

```bash
root@c378145551c4:/# apt-get install kubectl
```

konfiguracja projektu:

```bash
root@c378145551c4:~# gcloud config set project poznajk8s
```

Klaster można utowrzyć w konsoli Google Cloud Platform lub poleceniem:

```bash
root@c378145551c4:/# gcloud container clusters create poznajk8s-cluster-1 --zone us-central1-a --enable-cloud-logging --enable-cloud-monitoring --subnetwork default
```

Jeśli w konsoli to trzeba pobrać kredki do klastra:

```bash
root@c378145551c4:~# gcloud container clusters get-credentials poznajk8s-cluster-1 --zone us-central1-a

Fetching cluster endpoint and auth data.
kubeconfig entry generated for poznajk8s-cluster-1.
```

Drugą konsole można mieć z Cloud Shell

Niezależnie od metody powinniśmy uzyskać efekt następujący:

```bash
root@c378145551c4:/# kubectl get nodes

NAME                                                 STATUS   ROLES    AGE   VERSION
gke-poznajk8s-cluster-1-default-pool-cd8f12b8-3k0q   Ready    <none>   35s   v1.13.11-gke.23
gke-poznajk8s-cluster-1-default-pool-cd8f12b8-bz62   Ready    <none>   37s   v1.13.11-gke.23
gke-poznajk8s-cluster-1-default-pool-cd8f12b8-dmsf   Ready    <none>   35s   v1.13.11-gke.23
```

Usuwanie klastra:

```bash
root@83d84e765151:~# gcloud container clusters delete poznajk8s-cluster-1 --zone us-central1-a
The following clusters will be deleted.
 - [poznajk8s-cluster-1] in [us-central1-a]

Do you want to continue (Y/n)?  y
```


# Przetestuj tworzenie DaemonSet na swojej aplikacji lub korzystając z obrazu PKAD

tworzymy template dla daemontset i zapisujemy

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: daemon-rolling-update
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      name: pkad
  template:
    metadata:
      labels:
        name: pkad
    spec:
      containers:
      - name: pkad
        image: poznajkubernetes/pkad:blue
        resources:
              limits:
                memory: "128Mi"
                cpu: "200m"
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
```
następnie dodajemy konfigurację do naszego klastra

``` kubectl apply -f daemon-rollingUpdate.yaml```

sprawdzamy:

```bash
root@83d84e765151:~# kubectl get daemonset

NAME                    DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemon-rolling-update   3         3         3       3            3           <none>          47s
```

```bash
root@83d84e765151:~# kubectl get pods

NAME                          READY   STATUS    RESTARTS   AGE
daemon-rolling-update-4hzlw   1/1     Running   0          96s
daemon-rolling-update-8kjqb   1/1     Running   0          96s
daemon-rolling-update-kcczm   1/1     Running   0          96s
```


Podmieniamy wersję image na `red`

``` kubectl apply -f daemon-rollingUpdate_red.yaml```

```bash
root@83d84e765151:~# kubectl rollout history ds daemon-rolling-update

daemonset.extensions/daemon-rolling-update
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

Widzimy podmiany kolejnych pod.
```bash
(poznajk8s)$ kubectl get pods -w

NAME                          READY   STATUS    RESTARTS   AGE
daemon-rolling-update-4hzlw   1/1     Running   0          7m26s
daemon-rolling-update-8kjqb   1/1     Running   0          7m26s
daemon-rolling-update-kcczm   1/1     Running   0          7m26s
daemon-rolling-update-kcczm   1/1   Terminating   0     7m32s
daemon-rolling-update-kcczm   0/1   Terminating   0     7m33s
daemon-rolling-update-kcczm   0/1   Terminating   0     7m34s
daemon-rolling-update-kcczm   0/1   Terminating   0     7m34s
daemon-rolling-update-kcczm   0/1   Terminating   0     7m34s
daemon-rolling-update-4ddpb   0/1   Pending   0     0s
daemon-rolling-update-4ddpb   0/1   Pending   0     0s
daemon-rolling-update-4ddpb   0/1   ContainerCreating   0     0s
daemon-rolling-update-4ddpb   0/1   Running   0     4s
daemon-rolling-update-4ddpb   1/1   Running   0     5s
daemon-rolling-update-8kjqb   1/1   Terminating   0     7m39s
daemon-rolling-update-8kjqb   0/1   Terminating   0     7m40s
daemon-rolling-update-8kjqb   0/1   Terminating   0     7m41s
daemon-rolling-update-8kjqb   0/1   Terminating   0     7m41s
daemon-rolling-update-b9ns2   0/1   Pending   0     0s
daemon-rolling-update-b9ns2   0/1   Pending   0     0s
daemon-rolling-update-b9ns2   0/1   ContainerCreating   0     0s
daemon-rolling-update-b9ns2   0/1   Running   0     3s
daemon-rolling-update-b9ns2   1/1   Running   0     4s
daemon-rolling-update-4hzlw   1/1   Terminating   0     7m45s
daemon-rolling-update-4hzlw   0/1   Terminating   0     7m46s
daemon-rolling-update-4hzlw   0/1   Terminating   0     7m47s
daemon-rolling-update-4hzlw   0/1   Terminating   0     7m47s
daemon-rolling-update-vqnwq   0/1   Pending   0     0s
daemon-rolling-update-vqnwq   0/1   Pending   0     0s
daemon-rolling-update-vqnwq   0/1   ContainerCreating   0     0s
daemon-rolling-update-vqnwq   0/1   Running   0     3s
daemon-rolling-update-vqnwq   1/1   Running   0     5s
```

Powtarzamy dla OnDelete

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: daemon-ondelete
spec:
  updateStrategy:
    type: OnDelete
  selector:
    matchLabels:
      name: pkad
  template:
    metadata:
      labels:
        name: pkad
    spec:
      containers:
      - name: pkad
        image: poznajkubernetes/pkad:blue
        resources:
              limits:
                memory: "128Mi"
                cpu: "200m"
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
```

następnie dodajemy konfigurację do naszego klastra

``` kubectl apply -f daemon-ondelete.yaml```

sprawdzamy:

```bash
root@83d84e765151:~# kubectl get daemonset

NAME              DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemon-ondelete   3         3         3       3            3           <none>          8s
```

```bash
root@83d84e765151:~# kubectl get pods

NAME                    READY   STATUS    RESTARTS   AGE
daemon-ondelete-lhxlm   1/1     Running   0          16s
daemon-ondelete-lv2g7   1/1     Running   0          16s
daemon-ondelete-rx4vx   1/1     Running   0          16s
```


Podmieniamy wersję image na `red`

``` kubectl apply -f daemon-ondelete_red.yaml```

```bash
root@83d84e765151:~# kubectl rollout history ds daemon-ondelete

daemonset.extensions/daemon-ondelete
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

Widzimy podmiany kolejnych pod.

```bash
(poznajk8s)$ kubectl get pods -w
NAME                    READY   STATUS    RESTARTS   AGE
daemon-ondelete-lhxlm   1/1     Running   0          5m31s
daemon-ondelete-lv2g7   1/1     Running   0          5m31s
daemon-ondelete-rx4vx   1/1     Running   0          5m31s
```

Nie ma żadnych zmian w pod. Pody z nową wersją pojawią się jak usuniemy istniejący:

```bash
root@83d84e765151:~# kubectl get pods

NAME                    READY   STATUS    RESTARTS   AGE
daemon-ondelete-lhxlm   1/1     Running   0          9m29s
daemon-ondelete-lv2g7   1/1     Running   0          9m29s
daemon-ondelete-rx4vx   1/1     Running   0          9m29s

root@83d84e765151:~# kubectl delete pod daemon-ondelete-lhxlm

pod "daemon-ondelete-lhxlm" deleted

root@83d84e765151:~# kubectl get pods

NAME                    READY   STATUS    RESTARTS   AGE
daemon-ondelete-bqzzt   1/1     Running   0          8s
daemon-ondelete-lv2g7   1/1     Running   0          9m58s
daemon-ondelete-rx4vx   1/1     Running   0          9m58s

root@83d84e765151:~# kubectl describe pod daemon-ondelete-bqzzt

Name:           daemon-ondelete-bqzzt
Namespace:      default
Priority:       0
Node:           gke-poznajk8s-cluster-1-default-pool-cd8f12b8-dmsf/10.128.0.6
Start Time:     Sat, 01 Feb 2020 17:29:16 +0000
Labels:         controller-revision-hash=5c6bf67b78
                name=pkad
                pod-template-generation=2
Annotations:    <none>
Status:         Running
IP:             10.16.1.6
IPs:            <none>
Controlled By:  DaemonSet/daemon-ondelete
Containers:
  pkad:
    Container ID:   docker://81b4a13ea743a39a7e0cdcf03d5e474ff537048c2604176bcd91cbce725f7f21
    Image:          poznajkubernetes/pkad:red
```

## Sprawdź zachowanie aktualizacji dla RollingUpdate, jak i dla OnDelete w przypadku błędnie działającego health check — może być błędny path w readinessProbe

Tworzy ponownie daemonset  ``` kubectl apply -f daemon-rollingUpdate.yaml```

Modyfikujemy readinessProbe aby był błędny:

```yaml
        readinessProbe:
          httpGet:
            path: /ready-error
            port: 8080
```

następnie dodajemy konfigurację do naszego klastra

``` kubectl apply -f daemon-rollingUpdate-error.yaml```

sprawdzamy cos się dzieje z podami oraz z daemonset:

```bash
(poznajk8s)$ kubectl get pods -w

NAME                          READY   STATUS    RESTARTS   AGE
daemon-rolling-update-8mqlc   1/1   Running   0     2s
daemon-rolling-update-xl4g7   1/1   Running   0     5s
daemon-rolling-update-trf7v   1/1   Running   0     5s
daemon-rolling-update-xl4g7   1/1   Terminating   0     15s
daemon-rolling-update-xl4g7   0/1   Terminating   0     16s
daemon-rolling-update-xl4g7   0/1   Terminating   0     17s
daemon-rolling-update-xl4g7   0/1   Terminating   0     17s
daemon-rolling-update-p6fjt   0/1   Pending   0     0s
daemon-rolling-update-p6fjt   0/1   Pending   0     0s
daemon-rolling-update-p6fjt   0/1   ContainerCreating   0     0s
daemon-rolling-update-p6fjt   0/1   Running   0     2s
```

```bash
rroot@83d84e765151:~# kubectl rollout status ds daemon-rolling-update

Waiting for daemon set "daemon-rolling-update" rollout to finish: 1 out of 3 new pods have been updated...
```

Jak widać nowy pod nie może osiągność stanu ready i nasz daemonset wisi.

Próbujemy z tego stanu zrobić `undo`

```bash
root@83d84e765151:~# kubectl rollout undo ds daemon-rolling-update

daemonset.extensions/daemon-rolling-update rolled back
```

```bash
(poznajk8s)$ kubectl get pods -w
NAME                          READY   STATUS    RESTARTS   AGE
daemon-rolling-update-8mqlc   1/1     Running   0          7m40s
daemon-rolling-update-p6fjt   0/1     Running   0          7m23s
daemon-rolling-update-trf7v   1/1     Running   0          7m40s
daemon-rolling-update-p6fjt   0/1   Terminating   0     7m36s
daemon-rolling-update-p6fjt   0/1   Terminating   0     7m37s
daemon-rolling-update-p6fjt   0/1   Terminating   0     7m38s
daemon-rolling-update-p6fjt   0/1   Terminating   0     7m38s
daemon-rolling-update-sng8w   0/1   Pending   0     0s
daemon-rolling-update-sng8w   0/1   Pending   0     0s
daemon-rolling-update-sng8w   0/1   ContainerCreating   0     0s
daemon-rolling-update-sng8w   0/1   Running   0     2s
daemon-rolling-update-sng8w   1/1   Running   0     8s
```

Pod który był w nowszej wersji jest usuwany i wstaje nowy w starszej.
Pozostałe nie zostały usunięte. Widać, że deamonset uwzględnił fakt, że nie zostały zaktualizowane wcześniej i juz są w właściwej wersji.

Podobnie robimy dla DeleteOn.

Tworzymy daemonset: ```kubectl apply -f daemon-ondelete.yaml```

Aplikujemy z zmienionym healthcheck: ```kubectl apply -f daemon-ondelete-error.yaml```

```bash
(poznajk8s)$ kubectl get pods -w

NAME                    READY   STATUS    RESTARTS   AGE
daemon-ondelete-7m48b   1/1     Running   0          16s
daemon-ondelete-gjwtw   1/1     Running   0          16s
daemon-ondelete-rbl6m   1/1     Running   0          16s
```

Stan podów bez zmian, więc wymuszamy zmianę

```bash
root@83d84e765151:~# kubectl delete pod daemon-ondelete-7m48b

pod "daemon-ondelete-7m48b" deleted

root@83d84e765151:~# kubectl delete pod daemon-ondelete-gjwtw

pod "daemon-ondelete-gjwtw" deleted

root@83d84e765151:~# kubectl get ds -o wide -w

NAME              DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE     CONTAINERS   IMAGES                       SELECTOR
daemon-ondelete   3         3         1       2            1           <none>          9m16s   pkad         poznajkubernetes/pkad:blue   name=pkad

```

```bash
ar_kedzierski@cloudshell:~ (poznajk8s)$ kubectl get pods -w
NAME                    READY   STATUS    RESTARTS   AGE
daemon-ondelete-7m48b   1/1     Running   0          16s
daemon-ondelete-gjwtw   1/1     Running   0          16s
daemon-ondelete-rbl6m   1/1     Running   0          16s
daemon-ondelete-7m48b   1/1   Terminating   0     5m13s
daemon-ondelete-7m48b   0/1   Terminating   0     5m13s
daemon-ondelete-7m48b   0/1   Terminating   0     5m14s
daemon-ondelete-7m48b   0/1   Terminating   0     5m14s
daemon-ondelete-rhcq7   0/1   Pending   0     0s
daemon-ondelete-rhcq7   0/1   Pending   0     0s
daemon-ondelete-rhcq7   0/1   ContainerCreating   0     0s
daemon-ondelete-rhcq7   0/1   Running   0     2s
daemon-ondelete-gjwtw   1/1   Terminating   0     7m37s
daemon-ondelete-gjwtw   0/1   Terminating   0     7m37s
daemon-ondelete-gjwtw   0/1   Terminating   0     7m38s
daemon-ondelete-gjwtw   0/1   Terminating   0     7m38s
daemon-ondelete-pc9pl   0/1   Pending   0     0s
daemon-ondelete-pc9pl   0/1   Pending   0     0s
daemon-ondelete-pc9pl   0/1   ContainerCreating   0     1s
daemon-ondelete-pc9pl   0/1   Running   0     3s
```

Tak jak wcześniej pody powstają, ale nie mają statusu ready

Sprawdzamy więc undo:

```bash
root@83d84e765151:~# kubectl rollout undo ds daemon-ondelete

daemonset.extensions/daemon-ondelete rolled back

(poznajk8s)$ kubectl get pods -w

NAME                    READY   STATUS    RESTARTS   AGE
daemon-ondelete-pc9pl   0/1     Running   0          4m45s
daemon-ondelete-rbl6m   1/1     Running   0          12m
daemon-ondelete-rhcq7   0/1     Running   0          7m9s
```

Nie ma zmian więc wymuszamy:

```bash
root@83d84e765151:~# kubectl delete pod daemon-ondelete-pc9pl

pod "daemon-ondelete-pc9pl" deleted

root@83d84e765151:~# kubectl delete pod daemon-ondelete-rbl6m

pod "daemon-ondelete-rbl6m" deleted

 kubectl get ds -o wide

NAME              DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE   CONTAINERS   IMAGES                      SELECTOR
daemon-ondelete   3         3         2       2            2           <none>          15m   pkad         poznajkubernetes/pkad:blue   name=pkad

```

```bash
(poznajk8s)$ kubectl get pods -w
NAME                    READY   STATUS    RESTARTS   AGE
daemon-ondelete-pc9pl   0/1     Running   0          4m45s
daemon-ondelete-rbl6m   1/1     Running   0          12m
daemon-ondelete-rhcq7   0/1     Running   0          7m9s
daemon-ondelete-pc9pl   0/1   Terminating   0     6m43s
daemon-ondelete-pc9pl   0/1   Terminating   0     6m44s
daemon-ondelete-pc9pl   0/1   Terminating   0     6m45s
daemon-ondelete-pc9pl   0/1   Terminating   0     6m45s
daemon-ondelete-m2sw7   0/1   Pending   0     0s
daemon-ondelete-m2sw7   0/1   Pending   0     0s
daemon-ondelete-m2sw7   0/1   ContainerCreating   0     0s
daemon-ondelete-m2sw7   0/1   Running   0     2s
daemon-ondelete-m2sw7   1/1   Running   0     11s
daemon-ondelete-rbl6m   1/1   Terminating   0     14m
daemon-ondelete-rbl6m   0/1   Terminating   0     14m
daemon-ondelete-rbl6m   0/1   Terminating   0     14m
daemon-ondelete-rbl6m   0/1   Terminating   0     14m
daemon-ondelete-q6hk9   0/1   Pending   0     0s
daemon-ondelete-q6hk9   0/1   Pending   0     0s
daemon-ondelete-q6hk9   0/1   ContainerCreating   0     0s
daemon-ondelete-q6hk9   0/1   Running   0     2s
daemon-ondelete-q6hk9   1/1   Running   0     8s
```

Pody dzięki powrotowi do starszej wersji wstają, ale trzeba to wymuszać poprzez kasowanie wcześniej istniejacych podów.
