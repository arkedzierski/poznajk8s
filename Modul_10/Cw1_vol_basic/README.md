# Wolumeny w Pod – Ćwiczenia

## Przypomnij sobie jak działa emptyDir i hostPath. Powtórz ćwiczenia z lekcji Kontenery typu Init – ćwiczenia dla utrwalenia informacji. Możesz zmodyfikować zadanie by pobierać i cachować repozytorium git z wykorzystaniem hostPath

```bash

(⎈ |minikube:default)]$ kubectl apply -f Init_git_emptyDir.yaml
pod/www-ed created

(⎈ |minikube:default)]$ kubectl apply -f Init_git_hostpath.yaml
pod/www-hp created

(⎈ |minikube:default)]$ minikube ssh
                         _             _
            _         _ ( )           ( )
  ___ ___  (_)  ___  (_)| |/')  _   _ | |_      __
/' _ ` _ `\| |/' _ `\| || , <  ( ) ( )| '_`\  /'__`\
| ( ) ( ) || || ( ) || || |\`\ | (_) || |_) )(  ___/
(_) (_) (_)(_)(_) (_)(_)(_) (_)`\___/'(_,__/'`\____)

$ ls -l /temp/git
ls -l /temp/git
total 416
-rw-r--r-- 1 root root    19 Feb  2 21:23 CNAME
-rw-r--r-- 1 root root 24295 Feb  2 21:23 about.html
-rw-r--r-- 1 root root 16316 Feb  2 21:23 agenda.html
-rw-r--r-- 1 root root 25136 Feb  2 21:23 blog-single.html
-rw-r--r-- 1 root root 24742 Feb  2 21:23 blog.html
-rw-r--r-- 1 root root 16566 Feb  2 21:23 contact.html
drwxr-xr-x 3 root root   240 Feb  2 21:23 css
-rw-r--r-- 1 root root 17685 Feb  2 21:23 ebook.html
drwxr-xr-x 2 root root    60 Feb  2 21:23 files
drwxr-xr-x 2 root root   440 Feb  2 21:23 fonts
drwxr-xr-x 9 root root   600 Feb  2 21:23 images
-rw-r--r-- 1 root root 34358 Feb  2 21:23 index-2.html
-rw-r--r-- 1 root root 41926 Feb  2 21:23 index-3.html
-rw-r--r-- 1 root root 30092 Feb  2 21:23 index-4.html
-rw-r--r-- 1 root root 55413 Feb  2 21:23 index.html
drwxr-xr-x 2 root root   300 Feb  2 21:23 js
-rw-r--r-- 1 root root 27352 Feb  2 21:23 package-lock.json
-rw-r--r-- 1 root root 12507 Feb  2 21:23 policy.html
-rw-r--r-- 1 root root 15882 Feb  2 21:23 price.html
-rw-r--r-- 1 root root  1069 Feb  2 21:23 sendemail.php
-rw-r--r-- 1 root root 16316 Feb  2 21:23 service-detail.html
-rw-r--r-- 1 root root 25540 Feb  2 21:23 services.html
```

EmptyDir istniej tak długo jak długo żyje pod.
HostPath istniej tak długo jak długo żyje node.
Dla hostPath można sobie podejrzeć zawartość tego co się ściągneło na node.

Zawartość strony do sprawdzenia przez przeglądarkę po port-forward:

```kubectl port-forward www-ed 80:80```

```kubectl port-forward www-hp 80:80```

Co dziwne, dla emptyDir nie ma obrazków, a dla hostPath są.
Do sprawdzenia później.



## Wykonaj dwa zadania z subPath (dla ułatwienia skorzystaj z ConfigMap):

### Spróbuj nadpisać plik /etc/udhcpd.conf i zweryfikuj czy jego zawartość jest poprawna i czy zawartość innych plików w katalogu jest poprawna.

```bash
(⎈ |minikube:default)]$ kubectl apply -f subpath-overwrite-udhcpd.yaml

(⎈ |minikube:default)]$ kubectl exec subpath-overwrite-pod-udhcpd -- cat ./etc/udhcpd.conf

our new config
```

Plik został podmieniony zgodnie z oczekiwaniami

### Zrób to samo dla pliku /usr/bin/wget

```bash
(⎈ |minikube:default)]$ kubectl apply -f subpath-overwrite-wget.yaml

(⎈ |minikube:default)]$ kubectl exec subpath-overwrite-pod-wget -- cat ./usr/bin/wget

OCI runtime exec failed: exec failed: container_linux.go:345: starting container process caused "exec: \"cat\": executable file not found in $PATH": unknown

 (⎈ |minikube:default)]$ winpty kubectl exec -it subpath-overwrite-pod-wget sh

OCI runtime exec failed: exec failed: container_linux.go:345: starting container
 process caused "exec: \"sh\": executable file not found in $PATH": unknown
command terminated with exit code 126
```

Brak jest jakiejkolwiek możliwości dostania się do shell.

Jeśli uruchomimy busybox i sprawdzimy zawartość katalogu /usr/bin to mamy następujący wynik:

```bash
(⎈ |minikube:default)]$ winpty kubectl run pkad --image=poznajkubernetes/pkad --restart=Never --rm -it -- sh

(⎈ |minikube:default)]$ winpty kubectl exec -it subpath-overwrite-pod-wget sh
~ $ ls -l /usr/bin/wget

lrwxrwxrwx    1 root     root            12 Aug 20 10:30 /usr/bin/wget -> /bin/busybox

~ $ ls -l /usr/bin

total 224
lrwxrwxrwx    1 root     root            12 Aug 20 10:30 [ -> /bin/busybox
lrwxrwxrwx    1 root     root            12 Aug 20 10:30 [[ -> /bin/busybox
lrwxrwxrwx    1 root     root            12 Aug 20 10:30 awk -> /bin/busybox
lrwxrwxrwx    1 root     root            12 Aug 20 10:30 basename -> /bin/busybox
(...)
```

Wygląda na to, że wszystkie binarki są dowiązaniem do binarki busybox.
Jeśli nadpiszemy dowolną z nich to nadpisujemy całość i pod nie działa zbyt dobrze.

