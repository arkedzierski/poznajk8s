# Praca z ConfigMap

### Stwórz ConfigMap wykorzystując kubectl

* Załącz do niej przynajmniej dwie proste wartości (literal)
* Załącz do niej klucz: 123_TESTING z dowolną wartością
* Załącz do niej klucz: TESTING-123 z dowolną wartością
* Załącz do niej klucz: TESTING z dowolną wartością.

```bash
kubectl create cm cm1 --from-literal=123_TESTING=wartos1 --from-literal=TESTING-123=wartos2 --from-literal=TESTING=wartos3
```

```bash
kubectl describe cm cm1

Name:         cm1
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
TESTING-123:
----
wartos2
123_TESTING:
----
wartos1
TESTING:
----
wartos3
Events:  <none>
```

### Stwórz drugą ConfigMap wykorzystując kubectl

* Załącz do niej dwie takie same klucze i ale różne wartości
* Jeden plik normalnie
* Oraz jeden plik z inną nazwą klucza niż nazwa pliku

```bash
kubectl create cm cm2 --from-literal=TESTING=wartos1 --from-literal=TESTING=wartos2 --from-file=config.json --from-file=toml_config=config.toml

error: cannot add key "TESTING", another key by that name already exists in Data for ConfigMap "cm2"
```

```bash
kubectl get cm

NAME   DATA   AGE
cm1    3      15m
```

### Stwórz trzecią ostatnią ConfigMapę wykorzystując kubectl

* zrób tak by załączyć pliki o rozmiarach ~20KB, ~30KB, ~40KB i ~50KB

```python
import sys

N = int(sys.argv[1])

print("\n".join([ "key" + str(i) + " = value" + str(i) for i in range(N)]))
```

```bash
python generate.py 1100 > gen20.txt
```

```bash
python generate.py 1600 > gen30.txt
```

```bash
python generate.py 2100 > gen40.txt
```

```bash
python generate.py 2600 > gen50.txt
```

```bash
kubectl create cm cm3 --from-file=gen20.txt --from-file=gen30.txt --from-file=gen40.txt --from-file=gen50.txt
```

### Wyeksportuj wszystkie stworzone ConfigMapy do yamli

```bash
kubectl get cm cm1 -o yaml > cm1.yaml
```

```bash
kubectl create cm cm2 --from-literal=TESTING=wartos1 --from-literal=TESTING=wartos2 --from-file=config.json --from-file=toml_config=config.toml --dry-run=True -o yaml > cm2.yaml
```

```bash
kubectl get cm cm3 -o yaml > cm3.yaml
```


### Odpowiedz sobie na pytania

* Co się stanie gdy nadamy taki sam klucz? Czego Ty byś się spodziewał?

Dostaniemy błąd z informacją, że klucz z taką nazwą już istnieje. Nazwy kluczy w config mapie muszą być unikalne.

* Czy można nadać dowolną nazwę klucza w ConfigMap?

Nazwy kluczy muszą być zgodne z nazwami DNS. Dokładniej są sprawdzane wyrażeniem regularnym: `[-._a-zA-Z0-9]+`

# Zmienne środowiskowe

Będziemy korzystać z naszych ConfigMap z poprzedniej sekcji. Ćwiczenia te polegają na obserwowaniu wyniku akcji i zastanowieniu się dlaczego wynik jest taki a nie inny.

Dla Poda możesz skorzystać z własnego obrazu lub z obrazu poznajkubernetes/pkad

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-cm1
spec:
  containers:
  - name: pod-cm1
    image: poznajkubernetes/pkad:blue
    resources:
      limits:
        memory: "128Mi"
        cpu: "500m"
    envFrom:
      - configMapRef:
          name: cm1
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-cm3
spec:
  containers:
  - name: pod-cm3
    image: poznajkubernetes/pkad:blue
    resources:
      limits:
        memory: "128Mi"
        cpu: "500m"
    envFrom:
      - configMapRef:
          name: cm3
```

### Wczytaj wszystkie klucze z pierwszej ConfigMapy do Poda jako zmienne środowiskowe. Zweryfikuj dokładnie zmienne środowiskowe. Jaki wynik został uzyskany i dlaczego taki?

```bash
kubectl create -f pod_cm1.yaml
```

```bash
kubectl exec pod-cm1 -- printenv

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=pod-cm1
TESTING=wartos3
TESTING-123=wartos2
KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
KUBERNETES_SERVICE_HOST=10.96.0.1
KUBERNETES_SERVICE_PORT=443
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_PORT=tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP_PROTO=tcp
KUBERNETES_PORT_443_TCP_PORT=443
HOME=/
```

W Pod są widoczne wartości `TESTING` oraz `TESTING-123`. Natomiast wartość `123_TESTING` nie jest widoczna.

```bash
kubectl describe pod  pod-cm1

(..)
Warning  InvalidEnvironmentVariableNames  9m         kubelet, minikube  Keys [123_TESTING] from the EnvFrom configMap default/cm1 were skipped since they are considered invalid environment variable names.
(..)
```

### Wczytaj wszystkie klucze z trzeciej ConfigMapy do Poda jako zmienne środowiskowe. Zweryfikuj dokładnie zmienne środowiskowe. Jaki wynik został uzyskany i dlaczego taki?

```bash
kubectl create -f pod_cm3.yaml
```

```bash
kubectl port-forward pod-cm3 8080
```

Wszystkie klucze są widoczne poprawnie.

### Odpowiedz sobie na pytania:

* Co ma pierwszeństwo: zmienna środowiskowa zdefiniowana w ConfiMap czy w Pod?

Pierwszeństwo ma zmienna w Pod.

* Czy kolejność definiowania ma znaczenie (np.: env przed envFrom)?

Zmienne są wczytywane w kolejności definiowania w Pod. Jeżeli występują duplikaty nazw, to wartość zostanie nadpisana na ostatnią wartość dla tej nazwy.

* Jak się ma kolejność do dwóch różnych ConfigMap?

Jeżeli wczytywane są dwa różne ConfigMap zawierające taką samą nazwę klucza to ostateczna wartość klucza będzie ta ostatnio przypisana (z ostatniej wczytywanej ConfigMapy z tą zmienną).

# Wolumeny

### Wykorzystując drugą ConfigMapę stwórz Pod i wczytaj wszystkie pliki do katalogu wybranego przez siebie katalogu

```bash
kubectl create -f cm2.yaml
```
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-cm2-vol
spec:
  volumes:
    - name: cm2-volume
      configMap:
          name: cm2
  containers:
  - name: pod-cm2-vol
    image: poznajkubernetes/pkad:blue
    resources:
      limits:
        memory: "128Mi"
        cpu: "500m"
    volumeMounts:
      - mountPath: /etc/config
        name: cm2-volume
```

```bash
kubectl create -f pod_cm2_vol.yaml
```

```bash
kubectl exec pod-cm2-vol -- ls -l ./etc/config

total 0
lrwxrwxrwx    1 root     root            14 Dec 30 14:38 TESTING -> ..data/TESTING
lrwxrwxrwx    1 root     root            18 Dec 30 14:38 config.json -> ..data/config.json
lrwxrwxrwx    1 root     root            18 Dec 30 14:38 toml_config -> ..data/toml_config
```

### Wczytaj do wolumenu tylko i wyłącznie pliki powyżej 30KB z trzeciej ConfigMapy

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-cm3-vol
spec:
  volumes:
    - name: cm3-volume
      configMap:
          name: cm3
          items:
            - key: gen30.txt
              path: 30gen.txt
            - key: gen40.txt
              path: gen40.config
            - key: gen50.txt
              path: gen50.txt
  containers:
  - name: pod-cm3-vol
    image: poznajkubernetes/pkad:blue
    resources:
      limits:
        memory: "128Mi"
        cpu: "500m"
    volumeMounts:
      - mountPath: /etc/config
        name: cm3-volume
```

```bash
kubectl create -f pod_cm3_vol.yaml
```

```bash
kubectl exec pod-cm3-vol -- ls -l ./etc/config

total 0
lrwxrwxrwx    1 root     root            16 Dec 30 14:45 30gen.txt -> ..data/30gen.txt
lrwxrwxrwx    1 root     root            19 Dec 30 14:45 gen40.config -> ..data/gen40.config
lrwxrwxrwx    1 root     root            16 Dec 30 14:45 gen50.txt -> ..data/gen50.txt
```

### Odpowiedz sobie na pytania

* Co się stanie jak z mountPath ustawisz na katalog Twojej aplikacji?

Katalog aplikacji zostanie nadpisany tym co jest w `mountPath`

* Co się stanie jak plik stworzony przez ConfigMap zostanie usunięty? Czy taki plik zostanie usunięty?

Pliki są tylko do odczytu i nie mogą być usunięte.

* Co spowoduje aktualizacja ConfigMapy?

Plik zostanie zaktulizowany lub w przypadku nowego klucza i mapowania całości ConfigMap nowy plik zostanie utworzony.
