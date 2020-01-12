# Korzystając z wiedzy na temat rolling update przetestuj:

* Działanie trybu Recreate

    ```bash
    (⎈ |minikube:default)]$ kubectl create -f recreate.yaml
    ```

    Aktualizujemy deployment:

    ```bash
    (⎈ |minikube:default)]$ kubectl apply -f recreate_v2.yaml
    ```

    W innych konsolach moża zaobserwować działanie:

    `Deployment`

    ```bash
     (⎈ |minikube:default)]$ kubectl get deploy -w

    NAME   READY   UP-TO-DATE   AVAILABLE   AGE
    pkad   2/2     2            2           103s
    pkad   2/2     2            2           2m12s
    pkad   2/2     0            2           2m12s
    pkad   0/2     0            0           2m12s
    pkad   0/2     0            0           2m27s
    pkad   0/2     0            0           2m27s
    pkad   0/2     2            0           2m27s
    pkad   1/2     2            1           2m53s
    pkad   2/2     2            2           2m57s
    ```

    `ReplicaSet`

    ```bash
    (⎈ |minikube:default)]$ kubectl get replicaset -w

    NAME              DESIRED   CURRENT   READY   AGE
    pkad-5d6466774f   2         2         2       100s
    pkad-5d6466774f   0         2         2       2m12s
    pkad-5d6466774f   0         2         2       2m12s
    pkad-5d6466774f   0         0         0       2m12s
    pkad-765b449868   2         0         0       0s
    pkad-765b449868   2         0         0       0s
    pkad-765b449868   2         2         0       0s
    pkad-765b449868   2         2         1       26s
    pkad-765b449868   2         2         2       30s
    ```

    `Pods`

    ```bash
    (⎈ |minikube:default)]$ kubectl get pods -w

    NAME                    READY   STATUS    RESTARTS   AGE
    pkad-5d6466774f-7wptc   1/1     Running   0          83s
    pkad-5d6466774f-ffzbz   1/1     Running   0          83s
    pkad-5d6466774f-ffzbz   1/1     Terminating   0          2m12s
    pkad-5d6466774f-7wptc   1/1     Terminating   0          2m12s
    pkad-5d6466774f-ffzbz   0/1     Terminating   0          2m13s
    pkad-5d6466774f-7wptc   0/1     Terminating   0          2m14s
    pkad-5d6466774f-ffzbz   0/1     Terminating   0          2m14s
    pkad-5d6466774f-ffzbz   0/1     Terminating   0          2m16s
    pkad-5d6466774f-ffzbz   0/1     Terminating   0          2m16s
    pkad-5d6466774f-7wptc   0/1     Terminating   0          2m26s
    pkad-5d6466774f-7wptc   0/1     Terminating   0          2m27s
    pkad-765b449868-8xn5n   0/1     Pending       0          0s
    pkad-765b449868-8xn5n   0/1     Pending       0          0s
    pkad-765b449868-pp5l4   0/1     Pending       0          0s
    pkad-765b449868-pp5l4   0/1     Pending       0          0s
    pkad-765b449868-8xn5n   0/1     ContainerCreating   0          0s
    pkad-765b449868-pp5l4   0/1     ContainerCreating   0          0s
    pkad-765b449868-pp5l4   0/1     Running             0          2s
    pkad-765b449868-8xn5n   0/1     Running             0          2s
    pkad-765b449868-8xn5n   1/1     Running             0          26s
    pkad-765b449868-pp5l4   1/1     Running             0          30s
    ```

    Wnioski: Po aktualizacji wersji deployment usuwana jest aktualna ReplicaSet, a co za tym idzie wszystkie związne z nia pody i dopiero po jej usunięciu tworzona jest nowa oraz związane z nią pody.

* Szybki i wolny rolling update

    `Szybki`:

    ```yaml
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 1
    type: RollingUpdate
    ```
    
    ```bash
    (⎈ |minikube:default)]$ kubectl apply -f fast-update.yaml
    ```

    Aktualizujemy deployment:

    ```bash
    (⎈ |minikube:default)]$ kubectl apply -f recreate_v2.yaml
    ```

    W innych konsolach moża zaobserwować działanie:

    `Deployment`

    ```bash
     (⎈ |minikube:default)]$ kubectl get deploy -w

    NAME   READY   UP-TO-DATE   AVAILABLE   AGE
    pkad   3/3     3            3           6m31s
    pkad   3/3     3            3           6m51s
    pkad   3/3     3            3           6m51s
    pkad   3/3     0            3           6m51s
    pkad   2/3     0            2           6m51s
    pkad   2/3     2            2           6m51s
    pkad   2/3     3            2           6m51s
    pkad   3/3     3            3           7m14s
    pkad   3/3     3            3           7m14s
    pkad   2/3     3            2           7m14s
    pkad   3/3     3            3           7m22s
    pkad   3/3     3            3           7m22s
    pkad   2/3     3            2           7m23s
    pkad   3/3     3            3           7m50s
    ```

    `ReplicaSet`

    ```bash
    (⎈ |minikube:default)]$ kubectl get replicaset -w

    NAME              DESIRED   CURRENT   READY   AGE
    pkad-5d6466774f   3         3         3       77s
    pkad-765b449868   0         0         0       4m36s
    pkad-765b449868   0         0         0       4m53s
    pkad-765b449868   2         0         0       4m53s
    pkad-5d6466774f   2         3         3       94s
    pkad-765b449868   3         0         0       4m53s
    pkad-5d6466774f   2         3         3       94s
    pkad-5d6466774f   2         2         2       94s
    pkad-765b449868   3         0         0       4m53s
    pkad-765b449868   3         2         0       4m53s
    pkad-765b449868   3         3         0       4m53s
    pkad-765b449868   3         3         1       5m16s
    pkad-5d6466774f   1         2         2       117s
    pkad-5d6466774f   1         2         2       117s
    pkad-5d6466774f   1         1         1       117s
    pkad-765b449868   3         3         2       5m24s
    pkad-5d6466774f   0         1         1       2m5s
    pkad-5d6466774f   0         1         1       2m5s
    pkad-5d6466774f   0         0         0       2m6s
    pkad-765b449868   3         3         3       5m52s
    ```

    `Pods`

    ```bash
    (⎈ |minikube:default)]$ kubectl get pods -w

    NAME                    READY   STATUS    RESTARTS   AGE
    pkad-5d6466774f-h5nf9   1/1     Running   0          74s
    pkad-5d6466774f-r7r6m   1/1     Running   0          74s
    pkad-5d6466774f-tzdv9   1/1     Running   0          74s
    pkad-765b449868-v2wkz   0/1     Pending   0          0s
    pkad-5d6466774f-h5nf9   1/1     Terminating   0          94s
    pkad-765b449868-v2wkz   0/1     Pending       0          0s
    pkad-765b449868-88btv   0/1     Pending       0          0s
    pkad-765b449868-88btv   0/1     Pending       0          0s
    pkad-765b449868-v2wkz   0/1     ContainerCreating   0          0s
    pkad-765b449868-nw2dj   0/1     Pending             0          0s
    pkad-765b449868-nw2dj   0/1     Pending             0          0s
    pkad-5d6466774f-h5nf9   0/1     Terminating         0          96s
    pkad-765b449868-v2wkz   0/1     Running             0          2s
    pkad-5d6466774f-h5nf9   0/1     Terminating         0          97s
    pkad-5d6466774f-h5nf9   0/1     Terminating         0          97s
    pkad-765b449868-88btv   0/1     Pending             0          3s
    pkad-765b449868-88btv   0/1     ContainerCreating   0          3s
    pkad-765b449868-88btv   0/1     Running             0          5s
    pkad-765b449868-v2wkz   1/1     Running             0          23s
    pkad-5d6466774f-tzdv9   1/1     Terminating         0          117s
    pkad-5d6466774f-tzdv9   0/1     Terminating         0          118s
    pkad-765b449868-88btv   1/1     Running             0          31s
    pkad-5d6466774f-r7r6m   1/1     Terminating         0          2m5s
    pkad-5d6466774f-r7r6m   0/1     Terminating         0          2m6s
    pkad-5d6466774f-tzdv9   0/1     Terminating         0          2m6s
    pkad-5d6466774f-tzdv9   0/1     Terminating         0          2m7s
    pkad-765b449868-nw2dj   0/1     Pending             0          33s
    pkad-765b449868-nw2dj   0/1     ContainerCreating   0          33s
    pkad-5d6466774f-r7r6m   0/1     Terminating         0          2m8s
    pkad-5d6466774f-r7r6m   0/1     Terminating         0          2m8s
    pkad-765b449868-nw2dj   0/1     Running             0          35s
    pkad-765b449868-nw2dj   1/1     Running             0          59s
    ```

    Wnioski: Tworzone są 3 pody wraz z zmianą wersji i w miarę jak zwalniane są zasoby pody się uruchamiają. `Uwaga` ze względu na brak zasobów pody są w statusie pending. Gdyby były zasoby to działanie polegałoby na uruchamianiu 3 nowych podów i pilnowaniu aby działał 1 mniej niż zadeklarowno. Po uruchomieniu nowe zostawałby usunięty stary i na to miejsce znów uruchamiany nowy.

    `Powolny:`

    ```yaml
    strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
    type: RollingUpdate
    ```

    ```bash
    (⎈ |minikube:default)]$ kubectl create -f slow-update.yaml
    ```

    Aktualizujemy deployment:

    ```bash
    (⎈ |minikube:default)]$ kubectl apply -f slow-update_v2.yaml
    ```

    W innych konsolach moża zaobserwować działanie:

    `Deployment`

    ```bash
     (⎈ |minikube:default)]$ kubectl get deploy -w

    NAME   READY   UP-TO-DATE   AVAILABLE   AGE
    pkad   2/2     2            2           78s
    pkad   2/2     2            2           99s
    pkad   2/2     2            2           99s
    pkad   2/2     0            2           99s
    pkad   2/2     1            2           99s
    pkad   3/2     1            3           2m3s
    pkad   2/2     1            2           2m3s
    pkad   2/2     2            2           2m3s
    ```

    `ReplicaSet`

    ```bash
    (⎈ |minikube:default)]$ kubectl get replicaset -w

    NAME              DESIRED   CURRENT   READY   AGE
    pkad-5d6466774f   2         2         2       78s
    pkad-765b449868   1         0         0       0s
    pkad-765b449868   1         0         0       0s
    pkad-765b449868   1         1         0       0s
    pkad-765b449868   1         1         1       24s
    pkad-5d6466774f   1         2         2       2m3s
    pkad-765b449868   2         1         1       24s
    pkad-5d6466774f   1         2         2       2m3s
    pkad-5d6466774f   1         1         1       2m3s
    pkad-765b449868   2         1         1       24s
    pkad-765b449868   2         2         1       24s
    pkad-765b449868   2         2         2       53s
    pkad-5d6466774f   0         1         1       2m32s
    pkad-5d6466774f   0         1         1       2m32s
    pkad-5d6466774f   0         0         0       2m32s
    ```

    `Pods`

    ```bash
    (⎈ |minikube:default)]$ kubectl get pods -w

    NAME                    READY   STATUS    RESTARTS   AGE
    pkad-5d6466774f-25rvh   1/1     Running   0          81s
    pkad-5d6466774f-xffbp   1/1     Running   0          81s
    pkad-765b449868-8nddz   0/1     Pending   0          0s
    pkad-765b449868-8nddz   0/1     Pending   0          0s
    pkad-765b449868-8nddz   0/1     ContainerCreating   0          0s
    pkad-765b449868-8nddz   0/1     Running             0          2s
    pkad-765b449868-8nddz   1/1     Running             0          24s
    pkad-5d6466774f-xffbp   1/1     Terminating         0          2m3s
    pkad-765b449868-m574k   0/1     Pending             0          0s
    pkad-765b449868-m574k   0/1     Pending             0          0s
    pkad-765b449868-m574k   0/1     ContainerCreating   0          0s
    pkad-765b449868-m574k   0/1     Running             0          1s
    pkad-5d6466774f-xffbp   0/1     Terminating         0          2m4s
    pkad-5d6466774f-xffbp   0/1     Terminating         0          2m6s
    pkad-5d6466774f-xffbp   0/1     Terminating         0          2m6s
    pkad-765b449868-m574k   1/1     Running             0          29s
    pkad-5d6466774f-25rvh   1/1     Terminating         0          2m32s
    pkad-5d6466774f-25rvh   0/1     Terminating         0          2m33s
    pkad-5d6466774f-25rvh   0/1     Terminating         0          2m34s
    pkad-5d6466774f-25rvh   0/1     Terminating         0          2m34s
    ```

    Wnioski: Tworzony jest nowy pod i po jego uruchomieniu wyłączany stary. Nie domuszcza się do sytuacji, gdy pracuje mniej podów niż to zadeklarowane w deployment.

* Zmiany na deployment bez liveness i readiness

    ```bash
    (⎈ |minikube:default)]$ kubectl create -f recreate_no_Health_check.yaml
    ```

    ```bash
    (⎈ |minikube:default)]$ kubectl apply -f recreate_no_Health_check_v2.yaml
    ```

    Wnioski: Pody są dostępne praktycznie od razu po utworzeniu co może powodować HTTP 503 gdy aplikacja jeszcze nie jest gotowa na przyjmowanie ruchu.


* Zmiany na deployment z działającym readiness

    Sprawdzone na wcześniejszym ćwiczeniu, np

    ```bash
    (⎈ |minikube:default)]$ kubectl create -f slow-update.yaml
    ```

    ```bash
    (⎈ |minikube:default)]$ kubectl apply -f slow-update_v2.yaml
    ```

    Wnioski: Pod zostanie podmieniony gdy readiness zostanie sprawdzony.

* Zmiany na deployment z niedziałającym readiness (podaj np. błędny endpoint do sprawdzania)

    ```bash
    (⎈ |minikube:default)]$ kubectl create -f fast-update.yamll
    ```

    ```bash
    (⎈ |minikube:default)]$ kubectl apply -f fast-update_error.yam
    ```
    
    W innych konsolach moża zaobserwować działanie:

    `Deployment`

    ```bash
    (⎈ |minikube:default)]$ kubectl get deploy -w

    NAME   READY   UP-TO-DATE   AVAILABLE   AGE
    pkad   3/3     3            3           55s
    pkad   3/3     3            3           56s
    pkad   3/3     3            3           56s
    pkad   2/3     2            2           56s
    pkad   2/3     2            2           56s
    pkad   2/3     3            2           56s
    ```

    `ReplicaSet`

    ```bash
    (⎈ |minikube:default)]$ kubectl get replicaset -w

    NAME              DESIRED   CURRENT   READY   AGE
    pkad-5d6466774f   3         3         3       56s
    pkad-74595d567    2         0         0       0s
    pkad-5d6466774f   2         3         3       56s
    pkad-5d6466774f   2         3         3       56s
    pkad-74595d567    2         0         0       0s
    pkad-74595d567    2         2         0       0s
    pkad-5d6466774f   2         2         2       56s
    pkad-74595d567    3         2         0       0s
    pkad-74595d567    3         2         0       0s
    pkad-74595d567    3         3         0       0s
    ```

    `Pods`

    ```bash
    (⎈ |minikube:default)]$ kubectl get pods -w

    NAME                    READY   STATUS    RESTARTS   AGE
    pkad-5d6466774f-fgt2m   1/1     Terminating         0          58s
    pkad-5d6466774f-mmdrm   1/1     Running             0          58s
    pkad-5d6466774f-rgpmm   1/1     Running             0          58s
    pkad-74595d567-5mq27    0/1     Pending             0          2s
    pkad-74595d567-8zdpw    0/1     Pending             0          2s
    pkad-74595d567-99h7t    0/1     ContainerCreating   0          2s
    pkad-5d6466774f-fgt2m   0/1     Terminating         0          58s
    pkad-74595d567-99h7t    0/1     Running             0          2s
    pkad-5d6466774f-fgt2m   0/1     Terminating         0          69s
    pkad-5d6466774f-fgt2m   0/1     Terminating         0          69s
    pkad-74595d567-8zdpw    0/1     Pending             0          13s
    pkad-74595d567-8zdpw    0/1     ContainerCreating   0          14s
    pkad-74595d567-8zdpw    0/1     Running             0          16s
    ```

    ```bash
    (⎈ |minikube:default)]$ kubectl rollout status deployment pkad
    
    Waiting for deployment "pkad" rollout to finish: 2 old replicas are pending termination...
    ```

    Wnioski: Deployment nie postępuje, cały czas oczekuje readiness od nowych podów. Sytuację można naprawić wracaja do poprzedniej wersji deployment poleceniem ```kubectl rollout undo deployment pkad```