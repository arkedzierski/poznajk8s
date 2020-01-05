# Wykonaj podstawowe operacje na etykietach imperatywnie.

Takie operacje będą przydatne w późniejszych częściach szkolenia jak na przykład trzeba będzie przeanalizować niedziałający Pod albo przekierować ruch na inne Pody.

* Dodaj etykietę

```bash
kubectl label pod pkad test=True
```

* Dodaj etykietę do wszystkich zasobów na raz

```bash
kubectl label pods --all env=test
```

```bash
kubectl get pods --show-labels

NAME   READY   STATUS      RESTARTS   AGE     LABELS
bb     0/1     Completed   0          6m      env=test
pkad   1/1     Running     0          5m51s   env=test,test=True
```

* Zaktualizuj etykietę

```bash
kubectl label pod pkad --overwrite test=False
```

```bash
kubectl get pods --show-labels

NAME   READY   STATUS      RESTARTS   AGE     LABELS
bb     0/1     Completed   0          9m5s    env=test
pkad   1/1     Running     0          8m56s   env=test,test=False
```

* Usuń etykietę

```bash
kubectl label pod pkad test-
```

```bash
kubectl get pods --show-labels

NAME   READY   STATUS      RESTARTS   AGE   LABELS
bb     0/1     Completed   0          10m   env=test
pkad   1/1     Running     0          10m   env=test
```

# Stwórz trzy Pody z czego dwa posiadające po dwie etykiety: app=ui i env=test oraz app=ui i env=stg, trzeci bez etykiet

```bash
kubectl get pods --show-labels

NAME              READY   STATUS    RESTARTS   AGE   LABELS
pkad              1/1     Running   0          19m   <none>
pkad-label-stg    1/1     Running   0          66s   app=ui,env=stg
pkad-label-test   0/1     Pending   0          54s   app=ui,env=test
```

* Wybierz wszystkie Pody które mają etykietę env zdefiniowaną

```bash
kubectl get pods -l env

NAME              READY   STATUS    RESTARTS   AGE
pkad-label-stg    1/1     Running   0          2m46s
pkad-label-test   0/1     Pending   0          2m34s
```

* Wybierz wszystkie Pody które nie mają etykiety env zdefiniowanej

```bash
 kubectl get pods -l '!env'
 
NAME   READY   STATUS    RESTARTS   AGE
pkad   1/1     Running   0          22m
 ```
 
* Wybierz Pody które mają app=ui ale nie znajdują się w env=stg

```bash
kubectl get pods -l 'app=ui, env!=stg'

NAME              READY   STATUS    RESTARTS   AGE
pkad-label-test   0/1     Pending   0          9m45s
```

* Wybierz Pody których env znajduje się w przedziale stg i demo

```bash
kubectl get pods -l 'env in (stg,demo)'
NAME             READY   STATUS    RESTARTS   AGE
pkad-label-stg   1/1     Running   0          11m
```

# Z wcześniej stworzonych Podów:

* Wybierz i wyświetl tylko nazwy Poda

```bash
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'

pkad
pkad-label-stg
pkad-label-test
```

* Posortuj widok po dacie ostatniej aktualizacji Poda

```bash
kubectl get pods --sort-by=.metadata.creationTimestamp

NAME              READY   STATUS    RESTARTS   AGE
pkad              1/1     Running   0          34m
pkad-label-stg    1/1     Running   0          16m
pkad-label-test   0/1     Pending   0          16m
```

* Wybierz tylko i wyłączenie te Pody które nie są w fazie Running

```bash

kubectl get pods --field-selector=status.phase=Running
NAME             READY   STATUS    RESTARTS   AGE
pkad             1/1     Running   0          35m
pkad-label-stg   1/1     Running   0          17m
```