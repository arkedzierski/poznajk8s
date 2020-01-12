# Przetestuj każde z pytań w praktyce!

Pytania:

* Co się stanie kiedy dodasz Pod spełniający selektor ReplicaSet?

    Tworzymy ReplicaSet za pomocą yaml:

    ```bash
    (⎈ |minikube:default)]$ kubectl apply -f replica-set.yml

    (⎈ |minikube:default)]$ kubectl get replicaset

    NAME      DESIRED   CURRENT   READY   AGE
    pkad-rs   1         1         1       6m47s
    ```

    Tworzymy dodatkowy pod:

    ```bash
    (⎈ |minikube:default)]$ kubectl create -f replicaset_add_pod.yaml

    (⎈ |minikube:default)]$ kubectl get pods

    NAME             READY   STATUS        RESTARTS   AGE
    additional-pod   0/1     Terminating   0          1s
    pkad-rs-dhscl    1/1     Running       0          11m
    ```

    ReplicaSet pilnuje aby była właściwa ilość podów, więc dodatkowy pod jest od razu usuwany.

* Jak zadziała minReadySeconds bez readiness i liveliness probes?

    ```bash
    (⎈ |minikube:default)]$ kubectl apply -f helloapp-dep.yaml

    (⎈ |minikube:default)]$ kubectl get deploy -w

    NAME           READY   UP-TO-DATE   AVAILABLE   AGE
    helloapp-dep   0/2     0            0           0s
    helloapp-dep   0/2     0            0           1s
    helloapp-dep   0/2     0            0           1s
    helloapp-dep   0/2     2            0           1s
    helloapp-dep   1/2     2            0           3s
    helloapp-dep   2/2     2            0           3s
    helloapp-dep   2/2     2            2           13s
    ```

    Po ustawionym czasie od utworzenia ostatniego pod deployment jest AVAILABLE

* Do czego może Ci się przydać matchExpressions?

    Do określania podów które nie mają być zarządzane przez ReplicaSet.

* Jak najlepiej (według Ciebie) zarządzać historią zmian w deploymentach?

    Narzędzie CI/CD powinno wstawiać adnotację `kobernetes.io/change-cause` aby wiedzieć skąd która wersja się pojawiła.

* Co się stanie jak usuniesz ReplicaSet stworzony przez Deployment?

    ```bash
    (⎈ |minikube:default)]$ kubectl delete replicaset helloapp-dep-768ccdfccd
    ```

    W tym czasie na innej konsoli:

    ```bash
    (⎈ |minikube:default)]$ kubectl get replicaset -w

    NAME                      DESIRED   CURRENT   READY   AGE
    helloapp-dep-768ccdfccd   2         2         2       8m46s
    helloapp-dep-768ccdfccd   2         2         2       9m10s
    helloapp-dep-768ccdfccd   2         0         0       0s
    helloapp-dep-768ccdfccd   2         0         0       1s
    helloapp-dep-768ccdfccd   2         2         0       1s
    helloapp-dep-768ccdfccd   2         2         1       3s
    helloapp-dep-768ccdfccd   2         2         2       3s
    helloapp-dep-768ccdfccd   2         2         2       13s
    ```

    ReplicaSet zostaje odtworzone przez Deployment

* Czy Pod może definiować więcej etykiet niż ReplicaSet ma zdefiniowane w selectorze?

    Tak.

* Czy ReplicaSet może definiować więcej etykiet w selektorze niz Pod ma zdefiniowane?

    Nie. Taka ReplicaSet, a co za tym idzie Deployment zakończy działanie z kodem błędu i nie powstanie.