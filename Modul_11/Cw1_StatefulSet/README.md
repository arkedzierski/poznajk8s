# Obiekt StatefulSets – Ćwiczenia

Na podstawie lekcji przetestuj:

* Tworzenie i aktualizację StatefulSets
* Działanie serwisu typu headless
* Skalowanie StatefulSets

Połącz wiedzę na temat kontenera typu init oraz wolumenów z StatefulSets. Za pomocą kontenera typu init pobierz stronę z repozytorium git. Pobrane dane muszą trafić na trwały wolumen i zostać wykorzystane do serwowania treści w głównym kontenerze (wykorzystaj nginx). Skorzystaj z materiałów po ćwiczeniach o kontenera typu init.

Jeśli nie posiadasz strony w repo możesz wykorzystać https://github.com/PoznajKubernetes/poznajkubernetes.github.io

## Tworzenie i aktualizację StatefulSets

Wgrywamy SS na klaster i sprawdzamy ja się tworzą pody:

```bash
(⎈ |minikube:default)]$ kubectl apply -f ss.yaml

statefulset.apps/stateful-git created


(⎈ |minikube:default)]$ kubectl get statefulset -w

NAME           READY   AGE
stateful-git   0/2     0s
stateful-git   0/2     0s
stateful-git   1/2     10s
stateful-git   2/2     22s

 (⎈ |minikube:default)]$ kubectl get pod -w
NAME             READY   STATUS    RESTARTS   AGE

stateful-git-0   0/1     Pending   0          0s
stateful-git-0   0/1     Pending   0          0s
stateful-git-0   0/1     Init:0/1   0          0s
stateful-git-0   0/1     Init:0/1   0          2s
stateful-git-0   0/1     PodInitializing   0          7s
stateful-git-0   1/1     Running           0          10s
stateful-git-1   0/1     Pending           0          0s
stateful-git-1   0/1     Pending           0          0s
stateful-git-1   0/1     Init:0/1          0          0s
stateful-git-1   0/1     Init:0/1          0          3s
stateful-git-1   0/1     PodInitializing   0          8s
stateful-git-1   1/1     Running           0          12s
```

Pody postają jeden po drugim ze względu na strategię `RollingUpade` która jest strategią domyślną, wybieraną wówczas gdy nie ma zadeklarowanej. Strategi podczas aktualizacji nie można zmienić, trzeba usnąć i stworzyć nowy Statefulset

Wprowadzamy modyfikację obrazu dla init-kontenera:

```bash
(⎈ |minikube:default)]$ kubectl apply -f ss_mod.yaml

statefulset.apps/stateful-git configured

(⎈ |minikube:default)]$ kubectl get statefulset -w

NAME           READY   AGE
stateful-git   2/2     4m2s
stateful-git   2/2     4m13s
stateful-git   2/2     4m13s
stateful-git   1/2     4m13s
stateful-git   1/2     4m16s
stateful-git   2/2     7m2s
stateful-git   1/2     7m3s
stateful-git   1/2     7m6s
stateful-git   2/2     10m


 (⎈ |minikube:default)]$ kubectl get pod -w
NAME             READY   STATUS    RESTARTS   AGE

stateful-git-0   1/1     Running   0          4m5s
stateful-git-1   1/1     Running   0          39s
stateful-git-1   1/1     Terminating   0          47s
stateful-git-1   0/1     Terminating   0          47s
stateful-git-1   0/1     Terminating   0          50s
stateful-git-1   0/1     Terminating   0          50s
stateful-git-1   0/1     Pending       0          0s
stateful-git-1   0/1     Pending       0          0s
stateful-git-1   0/1     Init:0/1      0          0s
stateful-git-1   0/1     Init:0/1      0          3s
stateful-git-1   0/1     PodInitializing   0          2m43s
stateful-git-1   1/1     Running           0          2m46s
stateful-git-0   1/1     Terminating       0          7m2s
stateful-git-0   0/1     Terminating       0          7m3s
stateful-git-0   0/1     Terminating       0          7m6s
stateful-git-0   0/1     Terminating       0          7m6s
stateful-git-0   0/1     Pending           0          0s
stateful-git-0   0/1     Pending           0          0s
stateful-git-0   0/1     Init:0/1          0          1s
stateful-git-0   0/1     Init:0/1          0          3s
stateful-git-0   0/1     PodInitializing   0          3m28s
stateful-git-0   1/1     Running           0          3m32s
```
Pody podmieniane są w odwrotnej kolejności do stworzenia (czyli od ostatnio stworzonego do najstarszego)

W przypadku strategii `OnDelete` aktualizacja pod następuje po usunięciu istniejącego poda (jak w przypadku DaemonSet)

## Działanie serwisu typu headless

Tworzymy StatefulSet z Service typu headless:

```(⎈ |minikube:default)]$ kubectl apply -f ss-pvc.yaml

service/pkad-svc created
statefulset.apps/pkad-ss created

(⎈ |minikube:default)]$ kubectl get pods -o wide

NAME        READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
pkad-ss-0   1/1     Running   0          63s   172.17.0.7   minikube   <none>           <none>
pkad-ss-1   1/1     Running   0          34s   172.17.0.8   minikube   <none>           <none>

(⎈ |minikube:default)]$ winpty kubectl run -it --rm tools --generator=run-pod/v1 --image=giantswarm/tiny-tools

If you don't see a command prompt, try pressing enter.
/ # nslookup pkad-svc
Server:         10.96.0.10
Address:        10.96.0.10#53

Name:   pkad-svc.default.svc.cluster.local
Address: 172.17.0.8
Name:   pkad-svc.default.svc.cluster.local
Address: 172.17.0.7

/ # nslookup pkad-ss-0.pkad-svc.default.svc.cluster.local

Server:         10.96.0.10#53
Address:
** server can't find pkad-ss-0.pkad-svc.default.svc.cluster.local: NXDOMAIN

/ # nslookup pkad-ss-1.pkad-svc.default.svc.cluster.local

Server:         10.96.0.10#53
Address:
** server can't find pkad-ss-1.pkad-svc.default.svc.cluster.local: NXDOMAIN
```

Próbują dostać się do POD widzimy, że nazwa nie jest poprawnie rozwiązywana.
Zobaczmy czy nie wynika to z faktu wpisania różnej nazwy service i temaplate pod.

```
(⎈ |minikube:default)]$ kubectl apply -f ss-headless.yaml

service/pkad-ss created
statefulset.apps/pkad-ss created

/ # nslookup pkad-ss

Server:         10.96.0.10
Address:        10.96.0.10#53

Name:   pkad-ss.default.svc.cluster.local
Address: 172.17.0.8
Name:   pkad-ss.default.svc.cluster.local
Address: 172.17.0.7

/ # nslookup pkad-ss-0.pkad-ss.default.svc.cluster.local

Server:         10.96.0.10
Address:        10.96.0.10#53

Name:   pkad-ss-0.pkad-ss.default.svc.cluster.local
Address: 172.17.0.7

/ # nslookup pkad-ss-1.pkad-ss.default.svc.cluster.local

Server:         10.96.0.10#53
Address:pkad-ss-1.pkad-ss.default.svc.cluster.local
Address: 172.17.0.8
```

:warning: Zmiana nazwy service headless pomogła.

PODy i service muszą mieć taką samą nazwę aby działało.

## Skalowanie StatefulSets

Zmieńmy ilość instancji statefulset do 4.
Zgodnie z domyślnym ustawieniem podManagementPolicy: "OrderedReady" powinny pojawiać się PODy kolejno jedn po starcie drugiego.

'''
(⎈ |minikube:default)]$ kubectl scale statefulset pkad-ss --replicas=4

statefulset.apps/pkad-ss scaled

(⎈ |minikube:default)]$ kubectl get pod -w

NAME        READY   STATUS    RESTARTS   AGE
pkad-ss-0   1/1     Running   0          6m30s
pkad-ss-1   1/1     Running   0          6m5s
pkad-ss-2   0/1     Pending   0          0s
pkad-ss-2   0/1     Pending   0          0s
pkad-ss-2   0/1     Pending   0          1s
pkad-ss-2   0/1     ContainerCreating   0          1s
pkad-ss-2   0/1     Running             0          3s
pkad-ss-2   1/1     Running             0          23s
pkad-ss-3   0/1     Pending             0          0s
pkad-ss-3   0/1     Pending             0          0s
pkad-ss-3   0/1     Pending             0          1s
pkad-ss-3   0/1     ContainerCreating   0          1s
pkad-ss-3   0/1     Running             0          3s
pkad-ss-3   1/1     Running             0          26s

(⎈ |minikube:default)]$ kubectl get statefulset -w

NAME      READY   AGE
pkad-ss   2/2     6m14s
pkad-ss   2/4     6m33s
pkad-ss   2/4     6m33s
pkad-ss   3/4     6m56s
pkad-ss   4/4     7m22s
```

wrócmy do poprzedniego ustawienia

```
(⎈ |minikube:default)]$ kubectl scale statefulset pkad-ss --replicas=2

statefulset.apps/pkad-ss scaled

(⎈ |minikube:default)]$ kubectl get pod -w

NAME        READY   STATUS    RESTARTS   AGE
pkad-ss-0   1/1     Running   0          8m57s
pkad-ss-1   1/1     Running   0          8m32s
pkad-ss-2   1/1     Running   0          2m24s
pkad-ss-3   1/1     Running   0          2m1s
pkad-ss-3   1/1     Terminating   0          2m9s
pkad-ss-3   0/1     Terminating   0          2m10s
pkad-ss-3   0/1     Terminating   0          2m14s
pkad-ss-3   0/1     Terminating   0          2m14s
pkad-ss-2   1/1     Terminating   0          2m37s
pkad-ss-2   0/1     Terminating   0          2m37s
pkad-ss-2   0/1     Terminating   0          2m47s
pkad-ss-2   0/1     Terminating   0          2m47s

(⎈ |minikube:default)]$ kubectl get statefulset -w

NAME      READY   AGE
pkad-ss   4/4     9m1s
pkad-ss   4/2     9m5s
pkad-ss   4/2     9m6s
pkad-ss   3/2     9m6s
pkad-ss   3/2     9m10s
pkad-ss   2/2     9m10s
pkad-ss   2/2     9m20s
```

Pody kasowane są w odwrotnej kolejności do dodania.