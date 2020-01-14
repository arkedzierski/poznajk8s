# Deployment i skalowanie

* Stwórz Deployment dla Podów które w poprzednim module Twoje serwisy udostępniały


* Spróbuj to zrobić deklaratywnie i imperatywnie – Deployment jak i Serwis

```bash
$ kubectl create deployment pkad --image=poznajkubernetes/pkad:blue
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: pkad
  name: pkad
spec:
  replicas: 1
  selector:
    matchLabels:
      app: pkad
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: pkad
    spec:
      containers:
      - image: poznajkubernetes/pkad:blue
        name: pkad
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
```

```bash
$ kubectl get deployment

NAME   READY   UP-TO-DATE   AVAILABLE   AGE
pkad   1/1     1            1           4m2s
```

* Zeskaluj aplikację do 3 replik

```bash
$ kubectl scale deployment pkad --replicas=3 --record

$ kubectl get deployment

NAME   READY   UP-TO-DATE   AVAILABLE   AGE
pkad   3/3     3            3           82s
```

* Zeskaluj aplikację do 1 repliki jeżeli aktualnie ma ona 3 działające repliki

```
$ kubectl scale deployment pkad --replicas=1 --record

$ kubectl get deployment

NAME   READY   UP-TO-DATE   AVAILABLE   AGE
pkad   1/1     1            1           108s
```

* Wyciągnij historię pierwszego deploymentu

```bash
$ kubectl rollout history deploy pkad --revision=1
deployment.apps/pkad with revision #1
Pod Template:
  Labels:       app=pkad
        pod-template-hash=767f969544
  Annotations:  kubernetes.io/change-cause: kubectl.exe scale deployment pkad --replicas=1 --record=true
  Containers:
   pkad:
    Image:      poznajkubernetes/pkad:blue
    Port:       <none>
    Host Port:  <none>
    Limits:
      cpu:      200m
      memory:   128Mi
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>
```

* Zweryfikuj, że deployment się udał

```bash
$ kubectl rollout status deploy pkad

deployment "pkad" successfully rolled out
```

* Zastanów się ile dodatkowych sekund potrzebuje Twoja aplikacja by poprawnie wystartować

Do sprawdzenia jak rzeczywisty projekt będzie tak daleko.
