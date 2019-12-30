# Korzystając z materiałów z lekcji przetestuj działania zmienne środowiskowe w praktyce

### Wykorzystaj proste zmienne środowiskowe

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pkad
spec:
  containers:
  - name: pkad
    image: poznajkubernetes/pkad:blue
    env:
    - name: ZMIENNA_1
      value: "Kocham"
    - name: ZMIENNA_2
      value: "K8s"
    resources: {}
```

### Wykorzystaj w args zmienne środowiskowe

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox
spec:
  restartPolicy: Never
  containers:
  - name: busybox
    image: busybox
    command: ["echo"]
    args: ["Narzędzie $(TOOLNAME), wersja $(VERSION)"]
    env:
    - name: TOOLNAME
      value: "busybox"
    - name: VERSION
      value: "latest"
    resources: {}
```

```bash
$ kubectl logs busybox
Narzędzie busybox, wersja latest
```

### Skorzystaj z możliwości przekazania informacji o pod poprzez zmienne środowiskowe

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pkad
spec:
  containers:
  - name: pkad
    image: poznajkubernetes/pkad:blue
    env:
    - name: MY_POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: MY_POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: MY_POD_SERVICE_ACCOUNT
      valueFrom:
        fieldRef:
          fieldPath: spec.serviceAccountName
    resources: {}
```
