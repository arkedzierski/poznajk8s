
# Moduł 10 – WolumenyPraca domowa

Spróbuj podpiąć się wykorzystując PersistentVolumeClaim pod inny dysk niż:

* emptyDir
* hostPath
* downwardAPI
* configMap
* secret
Jeżeli nie masz możliwość podpięcia się pod inny dysk, spróbuj typ local.

Wykorzystaj typ wolumenu: projected by połączyć przynajmniej dwa typy wolumenów.

---

## Konfiguracja środowiska

Użyjemy GKE w tym zadaniu ze względu na potrzebę więcej niż jednego noda.
Zobacz Moduł 9 Cw1, gdzie również GKE był wykorzystywany.

Ustawiamuy projekt:

```gcloud config set project poznajk8s```

Tworzymy klaster:

```gcloud container clusters create poznajk8s-cluster-1 --zone us-central1-a --enable-cloud-logging --enable-cloud-monitoring --subnetwork default```

Pobieramy kredki:

```gcloud container clusters get-credentials poznajk8s-cluster-1 --zone us-central1-a```

Sprawdzamy działanie:
```bash
cloudshell:~$ kubectl get nodes

NAME                                                 STATUS   ROLES    AGE     VERSION
gke-poznajk8s-cluster-1-default-pool-0a69f884-4ddt   Ready    <none>   5m53s   v1.13.11-gke.23
gke-poznajk8s-cluster-1-default-pool-0a69f884-d4r3   Ready    <none>   5m52s   v1.13.11-gke.23
gke-poznajk8s-cluster-1-default-pool-0a69f884-kx9f   Ready    <none>   5m53s   v1.13.11-gke.23
```

Sprawdzamy domyślny StorageClass:
```bash
cloudshell:~$ kubectl get sc

NAME                 PROVISIONER            AGE
standard (default)   kubernetes.io/gce-pd   10m

cloudshell:~$ kubectl describe sc standard

Name:                  standard
IsDefaultClass:        Yes
Annotations:           storageclass.kubernetes.io/is-default-class=true
Provisioner:           kubernetes.io/gce-pd
Parameters:            type=pd-standard
AllowVolumeExpansion:  True
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     Immediate
Events:                <none>
```

Wykorzystamy w ćwiczeniu GCEPersistentDisk (kubernetes.io/gce-pd) typu standard.
Więcej -> https://kubernetes.io/docs/concepts/storage/storage-classes/

---

## Podpinamy się pod GCEPersistentDisk z wykorzystaniem PVC.

gcePD może mieć accessModes tylko ReadWriteOnce lub ReadOnlyMany i tylko w w jednej z wybranych form jednocześnie.
Stworzymy więc PD i podepniemy go najpierw do jednego Node aby stworzyć plik index.html w ReadWriteOnce, a następnie zamontujemy do wielu POD na różnych klastrach w trybie ReadOnlyMany.

Tworzymy PD i pilk (uwaga, przed użyciem należy stworzyć dysk, sformatować i wrzucić plik index.html):

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gce-pv
spec:
  storageClassName: ""
  capacity:
    storage: 10G
  accessModes:
    - ReadOnlyMany
  gcePersistentDisk:
    pdName: poznajk8s-pd-disk1
    fsType: ext4
---
apiVersion: v1
kind: Namespace
metadata:
  name: testgke
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gce-pd-pvc
  namespace: testgke
spec:
  storageClassName: ""
  volumeName: gce-pv
  accessModes:
    - ReadOnlyMany
  resources:
    requests:
      storage: 200Mi
```

oraz dodajemy Deployment ktory stworzy 10 instacji ngnix z użyciem wcześniej pokazanego PVC:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gke-vol-dep
  namespace: testgke
spec:
  replicas: 10
  selector:
    matchLabels:
      app: webapp
  strategy: {}
  template:
    metadata:
      name: gke-vol-pod
      labels:
        app: webapp
    spec:
      containers:
        - image: nginx
          name: web
          ports:
            - containerPort: 80
          volumeMounts:
            - name: html
              mountPath: /usr/share/nginx/html
      volumes:
        - name: html
          persistentVolumeClaim:
            claimName: gce-pd-pvc
```

Sprawdźmy czy wszystko się wstało:
```bash
cloudshell:~ (poznajk8s)$ kubectl get pv -n testgke

NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                STORAGECLASS   REASON   AGE
gce-pv   10G        ROX            Retain           Bound    testgke/gce-pd-pvc                           19s

cloudshell:~ (poznajk8s)$ kubectl get pvc -n testgke

NAME         STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
gce-pd-pvc   Bound    gce-pv   10G        ROX                           41s

cloudshell:~$ kubectl get deployment -n testgke

NAME          READY   UP-TO-DATE   AVAILABLE   AGE
gke-vol-dep   2/10    10           2           2m52s

cloudshell:~$ kubectl get pods -n testgke -o wide

NAME                           READY   STATUS              RESTARTS   AGE     IP          NODE                                                 NOMINATED NODE   READINESS GATES
gke-vol-dep-6b6f96c89c-24zjf   1/1     Running             0          3m36s   10.16.0.8   gke-poznajk8s-cluster-1-default-pool-0a69f884-kx9f   <none>           <none>
gke-vol-dep-6b6f96c89c-2whdw   0/1     ContainerCreating   0          3m36s   <none>      gke-poznajk8s-cluster-1-default-pool-0a69f884-d4r3   <none>           <none>
gke-vol-dep-6b6f96c89c-gg9nx   1/1     Running             0          3m36s   10.16.0.9   gke-poznajk8s-cluster-1-default-pool-0a69f884-kx9f   <none>           <none>
gke-vol-dep-6b6f96c89c-j8zrk   0/1     ContainerCreating   0          3m36s   <none>      gke-poznajk8s-cluster-1-default-pool-0a69f884-4ddt   <none>           <none>
gke-vol-dep-6b6f96c89c-prvt2   0/1     ContainerCreating   0          3m36s   <none>      gke-poznajk8s-cluster-1-default-pool-0a69f884-d4r3   <none>           <none>
gke-vol-dep-6b6f96c89c-smnrk   0/1     ContainerCreating   0          3m36s   <none>      gke-poznajk8s-cluster-1-default-pool-0a69f884-d4r3   <none>           <none>
gke-vol-dep-6b6f96c89c-sqlsd   0/1     ContainerCreating   0          3m36s   <none>      gke-poznajk8s-cluster-1-default-pool-0a69f884-4ddt   <none>           <none>
gke-vol-dep-6b6f96c89c-tdcnp   0/1     ContainerCreating   0          3m36s   <none>      gke-poznajk8s-cluster-1-default-pool-0a69f884-4ddt   <none>           <none>
gke-vol-dep-6b6f96c89c-th4kv   0/1     ContainerCreating   0          3m36s   <none>      gke-poznajk8s-cluster-1-default-pool-0a69f884-d4r3   <none>           <none>
gke-vol-dep-6b6f96c89c-x7r9s   0/1     ContainerCreating   0          3m36s   <none>      gke-poznajk8s-cluster-1-default-pool-0a69f884-4ddt   <none>           <none>
```

Jak widać uruchomiły się wszystkie pody na nodzie `gke-poznajk8s-cluster-1-default-pool-0a69f884-kx9f`

Sprawdzamy powód:

```bash
cloudshell:~ (poznajk8s)$ kubectl describe pod gke-vol-dep-6b6f96c89c-2whdw -n testgke
Name:               gke-vol-dep-6b6f96c89c-2whdw
Namespace:          testgke
Priority:           0
PriorityClassName:  <none>
Node:               gke-poznajk8s-cluster-1-default-pool-0a69f884-d4r3/10.128.0.8
Start Time:         Mon, 10 Feb 2020 22:01:43 +0100
Labels:             app=webapp
                    pod-template-hash=6b6f96c89c
Annotations:        <none>
Status:             Pending
IP:
Controlled By:      ReplicaSet/gke-vol-dep-6b6f96c89c
Containers:
  web:
    Container ID:
    Image:          nginx
    Image ID:
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Waiting
      Reason:       ContainerCreating
    Ready:          False
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /usr/share/nginx/html from html (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-l24b2 (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             False
  ContainersReady   False
  PodScheduled      True
Volumes:
  html:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  gce-pd-pvc
    ReadOnly:   false
  default-token-l24b2:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-l24b2
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type     Reason              Age                 From                                                         Message
  ----     ------              ----                ----                                                         -------
  Warning  FailedScheduling    22m                 default-scheduler                                            pod has unbound immediate PersistentVolumeClaims (repeated 3times)
  Normal   Scheduled           22m                 default-scheduler                                            Successfully assigned testgke/gke-vol-dep-6b6f96c89c-2whdw to gke-poznajk8s-cluster-1-default-pool-0a69f884-d4r3
  Warning  FailedAttachVolume  13m (x3 over 22m)   attachdetach-controller                                      AttachVolume.Attach failed for volume "gce-pv" : googleapi: Error 400: RESOURCE_IN_USE_BY_ANOTHER_RESOURCE - The disk resource 'projects/poznajk8s/zones/us-central1-a/disks/poznajk8s-pd-disk1' is already being used by 'projects/poznajk8s/zones/us-central1-a/instances/gke-poznajk8s-cluster-1-default-pool-0a69f884-kx9f'
  Warning  FailedMount         16s (x10 over 20m)  kubelet, gke-poznajk8s-cluster-1-default-pool-0a69f884-d4r3  Unable to mount volumes for pod "gke-vol-dep-6b6f96c89c-2whdw_testgke(85610d28-4c48-11ea-b636-42010a800115)": timeout expired waiting for volumes to attach or mount for pod "testgke"/"gke-vol-dep-6b6f96c89c-2whdw". list of unmounted volumes=[html]. list of unattached volumes=[html default-token-l24b2]
```

Jak widać wolumen jest już używany i kolejny node nie może go użyć.

Sprawdzamy zatem czy strona się ładuje na uruchomionych PODach. W tym celu uruchamiamy pod pomocniczego:

```bash
cloudshell:~ (poznajk8s)$ kubectl run -it --rm tools --generator=run-pod/v1 --image=giantswarm/tiny-tools
If you don't see a command prompt, try pressing enter.

/ # curl 10.16.0.9
Hello world!!! This is gcePD!
/ # curl 10.16.0.8
Hello world!!! This is gcePD!
/ #
```

---

## Wykorzystaj typ wolumenu: projected by połączyć przynajmniej dwa typy wolumenów

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: vol-secret
type: Opaque
data:
  username: U2VjcmV0VXNlcg==
  password: U2VjcmV0UGFzc3dvcmQ=
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: vol-config
data:
  config: "defaultConfig"
---
apiVersion: v1
kind: Pod
metadata:
  name: volume-protected
spec:
  containers:
  - name: vol-protect
    image: busybox
    volumeMounts:
    - name: all-in-one
      mountPath: "/projected-volume"
      readOnly: true
    command: ["sleep", "3000"]
  volumes:
  - name: all-in-one
    projected:
      sources:
      - secret:
          name: vol-secret
          items:
            - key: username
              path: data/user
            - key: password
              path: data/pass
      - configMap:
          name: vol-config
          items:
            - key: config
              path: data/config
```

```
(⎈ |minikube:default)]$ kubectl apply -f volume_protected.yaml

secret/vol-secret created
configmap/vol-config created
pod/volume-protected created

(⎈ |minikube:default)]$ winpty kubectl exec -it volume-protected ls ./projected-volume/data

config  pass    user

(⎈ |minikube:default)]$ winpty kubectl exec -it volume-protected cat ./projected-volume/data/config

defaultConfig

(⎈ |minikube:default)]$ winpty kubectl exec -it volume-protected cat ./projected-volume/data/pass

SecretPassword

(⎈ |minikube:default)]$ winpty kubectl exec -it volume-protected cat ./projected-volume/data/user

SecretUser
``

:warning:
Uwaga: Aby działało wszystkie klucze muszą być wykorzystane. W innym wypadku mamy błąd tworzenia POD