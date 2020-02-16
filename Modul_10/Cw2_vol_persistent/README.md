# Persistent Volumes – Ćwiczenia

## Przepisz ćwiczenie z Wolumeny w Pod – Ćwiczenia tak by zostały wykorzystane wolumeny za pomocą:

* PersistentVolume i PersistentVolumeClaim (aby cache'ować repozytorium git za pomocą InitContainer)

Tworzymy PV i PVC:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: vol-pv
  labels:
    volume: demo
spec:
  storageClassName: ""
  capacity:
    storage: 10Mi
  persistentVolumeReclaimPolicy: Retain
  accessModes:
  - ReadWriteOnce
  hostPath:
    path: /temp/git/persistent_volume/retain
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: vol-pvc
spec:
  storageClassName: ""
  selector:
    matchLabels:
      volume: demo
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 0.5Mi
```

dodajemy użycie PV do definicji pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: vol-pod
  labels:
    name: www
spec:
  containers:
  - name: main
    image: nginx
    volumeMounts:
      - mountPath: /usr/share/nginx/html/
        name: repo
    resources:
      limits:
        memory: "128Mi"
        cpu: "200m"
    ports:
      - containerPort: 80
  initContainers:
    - name: init
      image: poznajk8s/ubuntugit:v1
      command:
        - git
        - clone
        - "https://github.com/PoznajKubernetes/poznajkubernetes.github.io"
        - /repo
      volumeMounts:
        - mountPath: /repo
          name: repo
  volumes:
  - name: repo
    persistentVolumeClaim:
        claimName: vol-pvc
```

Wgrywamy i sprawdzamy:

```bash
kubectl apply -f pv_pvc_git.yaml
```

widać jak wstaje PVC, PV i POD:

```bash
(⎈ |minikube:default)]$ kubectl get pvc -w

NAME      STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
vol-pvc   Pending                                                     0s
vol-pvc   Pending   vol-pv   0                                        0s
vol-pvc   Bound     vol-pv   10Mi       RWO                           0s

(⎈ |minikube:default)]$ kubectl get pv -w

NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM   STORAGECLASS   REASON   AGE
vol-pv   10Mi       RWO            Retain           Pending                                   0s
vol-pv   10Mi       RWO            Retain           Available                                   0s
vol-pv   10Mi       RWO            Retain           Available   default/vol-pvc                           0s
vol-pv   10Mi       RWO            Retain           Bound       default/vol-pvc                           0s

(⎈ |minikube:default)]$ kubectl get pods

NAME      READY   STATUS    RESTARTS   AGE
vol-pod   1/1     Running   0          15s
```

Sprawdzamy działanie strony:

```bash
(⎈ |minikube:default)]$ kubectl port-forward vol-pod 80:80
Forwarding from 127.0.0.1:80 -> 80
Forwarding from [::1]:80 -> 80
```

Należy pamiętać, że repo jest na minikube

```bash
(⎈ |minikube:default)]$ minikube ssh
                         _             _
            _         _ ( )           ( )
  ___ ___  (_)  ___  (_)| |/')  _   _ | |_      __
/' _ ` _ `\| |/' _ `\| || , <  ( ) ( )| '_`\  /'__`\
| ( ) ( ) || || ( ) || || |\`\ | (_) || |_) )(  ___/
(_) (_) (_)(_)(_) (_)(_)(_) (_)`\___/'(_,__/'`\____)

$ ls -l /temp/git/persistent_volume/retain/

total 416
-rw-r--r-- 1 root root    19 Feb  9 18:01 CNAME
-rw-r--r-- 1 root root 24295 Feb  9 18:01 about.html
-rw-r--r-- 1 root root 16316 Feb  9 18:01 agenda.html
-rw-r--r-- 1 root root 25136 Feb  9 18:01 blog-single.html
-rw-r--r-- 1 root root 24742 Feb  9 18:01 blog.html
-rw-r--r-- 1 root root 16566 Feb  9 18:01 contact.html
drwxr-xr-x 3 root root   240 Feb  9 18:01 css
-rw-r--r-- 1 root root 17685 Feb  9 18:01 ebook.html
drwxr-xr-x 2 root root    60 Feb  9 18:01 files
drwxr-xr-x 2 root root   440 Feb  9 18:01 fonts
drwxr-xr-x 9 root root   600 Feb  9 18:01 images
-rw-r--r-- 1 root root 34358 Feb  9 18:01 index-2.html
-rw-r--r-- 1 root root 41926 Feb  9 18:01 index-3.html
-rw-r--r-- 1 root root 30092 Feb  9 18:01 index-4.html
-rw-r--r-- 1 root root 55657 Feb  9 18:01 index.html
drwxr-xr-x 2 root root   300 Feb  9 18:01 js
-rw-r--r-- 1 root root 27352 Feb  9 18:01 package-lock.json
-rw-r--r-- 1 root root 12507 Feb  9 18:01 policy.html
-rw-r--r-- 1 root root 15882 Feb  9 18:01 price.html
-rw-r--r-- 1 root root  1069 Feb  9 18:01 sendemail.php
-rw-r--r-- 1 root root 16316 Feb  9 18:01 service-detail.html
-rw-r--r-- 1 root root 25540 Feb  9 18:01 services.html
```

:warning:

Pamiętać aby po stworzeniu podów usunąć katalog z repo :heavy_exclamation_mark:

Można użyć ścieżki `/c/Users/<nazwaKontaWindows>` aby minikube zapisywał na dysku lokalnym.

---

* PersistentVolumeClaim (zrobimy PersistenVolumeProvisioner aby dostarczyć plik konfiguracyjny za pomocą subpath)

Sprawdamy jaki mamy domyślny provisioner:

```bash
(⎈ |minikube:default)]$ kubectl get sc

NAME                 PROVISIONER                AGE
standard (default)   k8s.io/minikube-hostpath   14d
```

Tworzymy PVC i SC (używając domyślnego provisioner):

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: vol-pvc-sc-subpath
spec:
  storageClassName: "vol-sc"
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 0.5Mi
```

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: vol-sc
provisioner: k8s.io/minikube-hostpathh
reclaimPolicy: Retain
allowVolumeExpansion: true
```

modyfikujemy definicje pod i towrzymy całość:

```(⎈ |minikube:default)]$ kubectl apply -f pv_pvc_subpath.yaml```

Sprawdzamy czy PV został utworzony oraz czy POD ruszły:

```bash
(⎈ |minikube:default)]$ kubectl get pvc

NAME                 STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
vol-pvc-sc-subpath   Bound    pvc-c7182b0f-947b-401e-b18b-9c9b544a0fcf   512Ki      RWO            vol-sc         83s

(⎈ |minikube:default)]$ kubectl get pv

NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                        STORAGECLASS   REASON   AGE
pvc-c7182b0f-947b-401e-b18b-9c9b544a0fcf   512Ki      RWO            Delete           Bound    default/vol-pvc-sc-subpath   vol-sc                  87s

(⎈ |minikube:default)]$ kubectl get pods -o wide

NAME              READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
vol-pod-subpath   1/1     Running   0          67s   172.17.0.7   minikube   <none>           <none>
```

Sprawdzamy czy strona ładuje się poprawnie ```(⎈ |minikube:default)]$ kubectl port-forward vol-pod-subpath 80:80```

:warning:

Pomimo zastosowania własnego ReclaimPolicy w SC (Retain), w PV jest inny (Delete)

---

* Odpowiedz sobie na pytanie kiedy może Ci się przydać Twoja własna klasa StorageClass?

Swoja własna klasa StorageClass przyda się do obsługi dynamicznego tworzenia PV aby mieć kontrolę nad jej konfiguracją (provisioner, reclaimPolicy, volumeBindingMode).