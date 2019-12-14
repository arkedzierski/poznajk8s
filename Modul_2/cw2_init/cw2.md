# Ćwiczenie 2

Celem ćwiczenia jest pobranie strony www z repozytorium git za pomocą kontenera typu init. Pobrane dane muszą trafić na wolumen typu emptyDir i zostać wykorzystane do serwowania treści w głównym kontenerze.

* Do kontenera init z git zbuduj obraz na bazie ubuntu. Należy doinstalować git.
* Do kontenera serwującego treść wykorzystaj nginx.
* Jeśli nie posiadasz strony w repo możesz wykorzystać https://github.com/PoznajKubernetes/poznajkubernetes.github.io

### Docker - budowanie obrazu z git na bazie ubuntu i wrzucenie do hub.docker.com

Dockerfile:
```dockerfile
FROM ubuntu

RUN apt-get update && apt-get install -y git
```

Buduj i archiwizuj:
```bash
docker login
docker build -t poznajk8s/ubuntugit:v1 .
docker push poznajk8s/ubuntugit:v1
```

### K8s - tworzenie poda i sprawdzenie czy działa

Tworzymy i uruchamiamy poda:
```bash
kubectl apply -f Init_git_www.yml
```

Plik YAML:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: www
  labels:
    name: www
spec:
  containers:
  - name: main
    image: nginx
    volumeMounts:
      - mountPath: /usr/share/nginx/html
        name: repo
    resources:
      limits:
        memory: "128Mi"
        cpu: "500m"
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
    emptyDir: {}
```

Przekierowujemy port i sprawdzamy czy działa http://127.0.0.1:8080
```bash
kubectl port-forward www 8080:80
```
