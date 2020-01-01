# Część 1 – stworzenie własnego prywatnego repozytorium kontenerów

```bash
docker login repo.treescale.com --username login
```

```bash
doker pull poznajkubernetes/pkad:blue
```

```bash
docker images

REPOSITORY              TAG                 IMAGE ID            CREATED         SIZE
poznajkubernetes/pkad   blue                4305e828fdce        2 months ago    23MB
```

```bash
docker tag poznajkubernetes/pkad:blue repo.treescale.com/login/poznajk8s/pkad:blue_cp
```

```bash
docker push repo.treescale.com/login/poznajk8s/pkad:blue_cp
```

```bash
docker rmi repo.treescale.com/login/poznajk8s/pkad:blue_cp
docker rmi poznajkubernetes/pkad:blue
```

# Część 2 – wykorzystanie obrazu z prywatnego repozytorium

Utwórz Pod, który ściągnie obraz z prywatnego repozytorium. Musisz wykonać następujące kroki:

* Utworzyć secret typu kubernetes.io/dockerconfigjson na podstawie pliku .docker/config.json. 

```bash
kubectl create secret generic treescalecred --from-file=.dockerconfigjson=$USERPROFILE/.docker/config.json --type=kubernetes.io/dockerconfigjson
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-secret
  labels:
    name: pod-secret
spec:
  containers:
  - name: pod-secret
    image: repo.treescale.com/login/poznajk8s/pkad:blue_cp
    resources: {}
    ports:
      - containerPort: 8080
  imagePullSecrets:
    - name: treescalecred
```

```bash
kubectl apply -f pod_secret.yaml
```

```bash
kubectl.exe get pod -w

NAME         READY   STATUS    RESTARTS   AGE
pod-secret   1/1     Running   0          8s
```

```bash
kubectl.exe describe pod pod-secret

Name:         pod-secret
(...)
Events:
  Type    Reason     Age        From               Message
  ----    ------     ----       ----               -------
  Normal  Scheduled  <unknown>  default-scheduler  Successfully assigned default/pod-secret to minikube
  Normal  Pulling    2m47s      kubelet, minikube  Pulling image "repo.treescale.com/login/poznajk8s/pkad:blue_cp"
  Normal  Pulled     2m46s      kubelet, minikube  Successfully pulled image "repo.treescale.com/login/poznajk8s/pkad:blue_cp"
  Normal  Created    2m46s      kubelet, minikube  Created container pod-secret
  Normal  Started    2m46s      kubelet, minikube  Started container pod-secret
```

# Część 3 – stwórz secret i wykorzystaj go w Pod

Mając już obraz z prywatnego repozytorium, stwórz 2 rodzaje secret: --from-literal i --from-file, używając polecenia kubectl create. Gdy będziesz miał już je utworzone, spróbuj wykorzystać je jako pliki i/lub zmienne środowiskowe.

```bash
kubectl create secret generic literal-sec --from-literal=USERNAME=xyz --from-literal=PASSWORD=qwerty
```

```bash
kubectl create secret generic file-sec --from-file=AUTH=file-sec.txt
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-secret2
  labels:
    name: pod-secret2
spec:
  containers:
  - name: pod-secret2
    image: repo.treescale.com/login/poznajk8s/pkad:blue_cp
    envFrom:
      - secretRef:
          name: literal-sec
    volumeMounts:
      - mountPath: /secret/
        name: secret-volume
        readOnly: true
    resources: {}
    ports:
      - containerPort: 8080
  volumes:
    - name: secret-volume
      secret:
          secretName: file-sec
```

```bash
kubectl create -f pod_secret2.yaml
```

```bash
kubectl exec pod-secret2 -- printenv

HOSTNAME=pod-secret2
PASSWORD=qwerty
USERNAME=xyz
(...)
```

```bash
kubectl exec pod-secret2 -- cat ./secret/AUTH
USERNAME=zyx
PASSWORD=ytrewq
```
