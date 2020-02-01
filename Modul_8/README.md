# Stwórz CronJob tak aby:

## co 2 minuty tworzył on Job

```yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: cronjob-2m
spec:
  jobTemplate:
    metadata:
      name: cronjob-2m
    spec:
      template:
        spec:
          containers:
          - image: busybox
            name: cronjob-2m
            resources:
              limits:
                memory: "128Mi"
                cpu: "200m"
            command:
            - /bin/sh
            - -c
            - sleep 1m
          restartPolicy: Never
  schedule: "*/2 * * * *"
```

```
(⎈ |minikube:default)]$ kubectl delete -f cronJob_2m.yaml


(⎈ |minikube:default)]$ kubectl get cronjob -w
NAME         SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob-2m   */2 * * * *   False     0        <none>          25s
cronjob-2m   */2 * * * *   False     1        1s              2m1s
cronjob-2m   */2 * * * *   False     0        71s             3m11s
cronjob-2m   */2 * * * *   False     1        1s              4m1s
cronjob-2m   */2 * * * *   False     0        71s             5m11s
```

```bash
(⎈ |minikube:default)]$ kubectl get job -w

NAME                    COMPLETIONS   DURATION   AGE
cronjob-2m-1580159160   0/1                      0s
cronjob-2m-1580159160   0/1           0s         0s
cronjob-2m-1580159160   1/1           66s        66s
cronjob-2m-1580159280   0/1                      0s
cronjob-2m-1580159280   0/1           0s         0s
cronjob-2m-1580159280   1/1           64s        64s
```

```
(⎈ |minikube:default)]$ kubectl get pod -w
NAME                          READY   STATUS    RESTARTS   AGE
cronjob-2m-1580159160-krbgn   0/1     Pending   0          0s
cronjob-2m-1580159160-krbgn   0/1     Pending   0          0s
cronjob-2m-1580159160-krbgn   0/1     ContainerCreating   0          0s
cronjob-2m-1580159160-krbgn   1/1     Running             0          6s
cronjob-2m-1580159160-krbgn   0/1     Completed           0          66s
cronjob-2m-1580159280-rsw7q   0/1     Pending             0          0s
cronjob-2m-1580159280-rsw7q   0/1     Pending             0          0s
cronjob-2m-1580159280-rsw7q   0/1     ContainerCreating   0          0s
cronjob-2m-1580159280-rsw7q   1/1     Running             0          4s
cronjob-2m-1580159280-rsw7q   0/1     Completed           0          64s
```

CronJob uruchamia Job, który to tworzy pod z busybox.
Pod działą około minuty i kończy działanie

## stworzony Job powinien tworzyć 2 lub więcej chodzące Pod

```yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: cronjob-2m-p
spec:
  jobTemplate:
    metadata:
      name: cronjob-2m-p
    spec:
      parallelism: 2
      template:
        spec:
          containers:
          - image: busybox
            name: cronjob-2m-p
            resources:
              limits:
                memory: "128Mi"
                cpu: "200m"
            command:
            - /bin/sh
            - -c
            - sleep 1m
          restartPolicy: OnFailure
  schedule: "*/2 * * * *"
```

```bash
(⎈ |minikube:default)]$ kubectl create -f cronJob_2m_paraller.yaml
cronjob.batch/cronjob-2m-p created

(⎈ |minikube:default)]$ kubectl get cronjob -w NAME           SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob-2m-p   */2 * * * *   False     0        <none>          4s
cronjob-2m-p   */2 * * * *   False     1        2s              74s
cronjob-2m-p   */2 * * * *   False     0        72s             2m24s
cronjob-2m-p   */2 * * * *   False     1        2s              3m14s
cronjob-2m-p   */2 * * * *   False     0        73s             4m25s
```

```bash
(⎈ |minikube:default)]$ kubectl get job -w
NAME                      COMPLETIONS   DURATION   AGE
cronjob-2m-p-1580159880   0/1 of 2                 0s
cronjob-2m-p-1580159880   0/1 of 2      0s         0s
cronjob-2m-p-1580159880   1/1 of 2      65s        65s
cronjob-2m-p-1580159880   2/1 of 2      67s        67s
cronjob-2m-p-1580160000   0/1 of 2                 0s
cronjob-2m-p-1580160000   0/1 of 2      1s         1s
cronjob-2m-p-1580160000   0/1 of 2      0s         1s
cronjob-2m-p-1580160000   1/1 of 2      64s        65s
cronjob-2m-p-1580160000   2/1 of 2      66s        67s
```

```bash
(⎈ |minikube:default)]$ kubectl get pod -w
NAME                            READY   STATUS    RESTARTS   AGE
cronjob-2m-p-1580159880-486j8   0/1     Pending   0          0s
cronjob-2m-p-1580159880-486j8   0/1     Pending   0          0s
cronjob-2m-p-1580159880-gnqf9   0/1     Pending   0          0s
cronjob-2m-p-1580159880-gnqf9   0/1     Pending   0          0s
cronjob-2m-p-1580159880-486j8   0/1     ContainerCreating   0          0s
cronjob-2m-p-1580159880-gnqf9   0/1     ContainerCreating   0          0s
cronjob-2m-p-1580159880-gnqf9   1/1     Running             0          5s
cronjob-2m-p-1580159880-486j8   1/1     Running             0          6s
cronjob-2m-p-1580159880-gnqf9   0/1     Completed           0          65s
cronjob-2m-p-1580159880-486j8   0/1     Completed           0          67s
cronjob-2m-p-1580160000-ztv62   0/1     Pending             0          0s
cronjob-2m-p-1580160000-ztv62   0/1     Pending             0          0s
cronjob-2m-p-1580160000-swfml   0/1     Pending             0          0s
cronjob-2m-p-1580160000-ztv62   0/1     ContainerCreating   0          0s
cronjob-2m-p-1580160000-swfml   0/1     Pending             0          1s
cronjob-2m-p-1580160000-swfml   0/1     ContainerCreating   0          1s
cronjob-2m-p-1580160000-ztv62   1/1     Running             0          5s
cronjob-2m-p-1580160000-swfml   1/1     Running             0          7s
cronjob-2m-p-1580160000-ztv62   0/1     Completed           0          65s
cronjob-2m-p-1580160000-swfml   0/1     Completed           0          67s
```

Działanie jak wcześniej, z tą różnicą, że mamy 2 pody.

## Pody powinny chodzić więcej niż 2 minuty. Możesz na stałe zaszyć 3 minuty

```yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: cronjob-3m-p
spec:
  jobTemplate:
    metadata:
      name: cronjob-3m-p
    spec:
      parallelism: 2
      template:
        spec:
          containers:
          - image: busybox
            name: cronjob-3m-p
            resources:
              limits:
                memory: "128Mi"
                cpu: "200m"
            command:
            - /bin/sh
            - -c
            - sleep 3m
          restartPolicy: OnFailure
  schedule: "*/2 * * * *"
```

```bash
(⎈ |minikube:default)]$ kubectl create -f cronJob_3m_paraller.yaml
cronjob.batch/cronjob-3m-p created

(⎈ |minikube:default)]$ kubectl get cronjob -w NAME           SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob-3m-p   */2 * * * *   False     0        <none>          5s
cronjob-3m-p   */2 * * * *   False     1        3s              42s
cronjob-3m-p   */2 * * * *   False     2        3s              2m42s
cronjob-3m-p   */2 * * * *   False     1        74s             3m53s
cronjob-3m-p   */2 * * * *   False     2        4s              4m43s
cronjob-3m-p   */2 * * * *   False     1        74s             5m53s
```

```
(⎈ |minikube:default)]$ kubectl get job -w
NAME                      COMPLETIONS   DURATION   AGE
cronjob-3m-p-1580160360   0/1 of 2                 0s
cronjob-3m-p-1580160360   0/1 of 2      0s         0s
cronjob-3m-p-1580160480   0/1 of 2                 0s
cronjob-3m-p-1580160480   0/1 of 2      1s         1s
cronjob-3m-p-1580160360   1/1 of 2      3m4s       3m4s
cronjob-3m-p-1580160360   2/1 of 2      3m6s       3m6s
cronjob-3m-p-1580160600   0/1 of 2                 0s
cronjob-3m-p-1580160600   0/1 of 2      0s         0s
cronjob-3m-p-1580160480   1/1 of 2      3m5s       3m5s
cronjob-3m-p-1580160480   2/1 of 2      3m6s       3m6s
```

```
(⎈ |minikube:default)]$ kubectl get pod -w
NAME                            READY   STATUS    RESTARTS   AGE
cronjob-3m-p-1580160360-h6gqc   0/1     Pending   0          0s
cronjob-3m-p-1580160360-qtt5b   0/1     Pending   0          0s
cronjob-3m-p-1580160360-h6gqc   0/1     Pending   0          0s
cronjob-3m-p-1580160360-qtt5b   0/1     Pending   0          0s
cronjob-3m-p-1580160360-h6gqc   0/1     ContainerCreating   0          0s
cronjob-3m-p-1580160360-qtt5b   0/1     ContainerCreating   0          0s
cronjob-3m-p-1580160360-h6gqc   1/1     Running             0          4s
cronjob-3m-p-1580160360-qtt5b   1/1     Running             0          6s
cronjob-3m-p-1580160480-q6488   0/1     Pending             0          0s
cronjob-3m-p-1580160480-q6488   0/1     Pending             0          1s
cronjob-3m-p-1580160480-7d9ll   0/1     Pending             0          1s
cronjob-3m-p-1580160480-q6488   0/1     ContainerCreating   0          1s
cronjob-3m-p-1580160480-7d9ll   0/1     Pending             0          1s
cronjob-3m-p-1580160480-7d9ll   0/1     ContainerCreating   0          1s
cronjob-3m-p-1580160480-q6488   1/1     Running             0          5s
cronjob-3m-p-1580160480-7d9ll   1/1     Running             0          7s
cronjob-3m-p-1580160360-h6gqc   0/1     Completed           0          3m4s
cronjob-3m-p-1580160360-qtt5b   0/1     Completed           0          3m6s
cronjob-3m-p-1580160600-t5wlw   0/1     Pending             0          0s
cronjob-3m-p-1580160600-t5wlw   0/1     Pending             0          0s
cronjob-3m-p-1580160600-h2ltt   0/1     Pending             0          0s
cronjob-3m-p-1580160600-t5wlw   0/1     ContainerCreating   0          0s
cronjob-3m-p-1580160600-h2ltt   0/1     Pending             0          0s
cronjob-3m-p-1580160600-h2ltt   0/1     ContainerCreating   0          0s
cronjob-3m-p-1580160600-h2ltt   1/1     Running             0          4s
cronjob-3m-p-1580160600-t5wlw   1/1     Running             0          6s
cronjob-3m-p-1580160480-q6488   0/1     Completed           0          3m5s
cronjob-3m-p-1580160480-7d9ll   0/1     Completed           0          3m6s
```

Joby pracują równolegle, nie ma znaczenia czy wcześniejszy się zakończył, czy też nie.

## używając parametru concurrencyPolicy spróbuj uzyskać efekt, aby nowo utworzone Pod zastępowały stare, czyli nigdy żaden z Pod się nie zakończy

```yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: cronjob-3m-p-c
spec:
  jobTemplate:
    metadata:
      name: cronjob-3m-p-c
    spec:
      parallelism: 2
      template:
        spec:
          containers:
          - image: busybox
            name: cronjob-3m-p-c
            resources:
              limits:
                memory: "128Mi"
                cpu: "200m"
            command:
            - /bin/sh
            - -c
            - sleep 3m
          restartPolicy: OnFailure
  schedule: "*/2 * * * *"
  concurrencyPolicy: Replace
```

```bash
(⎈ |minikube:default)]$ kubectl create -f cronJob_3m_paraller_con.yaml
cronjob.batch/cronjob-3m-p-c created

(⎈ |minikube:default)]$ kubectl get cronjob -w NAME             SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob-3m-p-c   */2 * * * *   False     0        <none>          4s
cronjob-3m-p-c   */2 * * * *   False     1        4s              21s
cronjob-3m-p-c   */2 * * * *   False     1        5s              2m22s
```

```bash
(⎈ |minikube:default)]$ kubectl get job -w
NAME                        COMPLETIONS   DURATION   AGE
cronjob-3m-p-c-1580160960   0/1 of 2                 0s
cronjob-3m-p-c-1580160960   0/1 of 2      0s         0s
cronjob-3m-p-c-1580160960   0/1 of 2      2m1s       2m1s
cronjob-3m-p-c-1580161080   0/1 of 2                 0s
cronjob-3m-p-c-1580161080   0/1 of 2      0s         0s
```

```bash
(⎈ |minikube:default)]$ kubectl get pod -w
NAME                              READY   STATUS    RESTARTS   AGE
cronjob-3m-p-c-1580160960-ddwc5   0/1     Pending   0          0s
cronjob-3m-p-c-1580160960-ddwc5   0/1     Pending   0          0s
cronjob-3m-p-c-1580160960-279k5   0/1     Pending   0          0s
cronjob-3m-p-c-1580160960-279k5   0/1     Pending   0          0s
cronjob-3m-p-c-1580160960-ddwc5   0/1     ContainerCreating   0          0s
cronjob-3m-p-c-1580160960-279k5   0/1     ContainerCreating   0          1s
cronjob-3m-p-c-1580160960-ddwc5   1/1     Running             0          4s
cronjob-3m-p-c-1580160960-279k5   1/1     Running             0          6s
cronjob-3m-p-c-1580161080-98f84   0/1     Pending             0          0s
cronjob-3m-p-c-1580161080-98f84   0/1     Pending             0          0s
cronjob-3m-p-c-1580161080-6xndr   0/1     Pending             0          0s
cronjob-3m-p-c-1580161080-98f84   0/1     ContainerCreating   0          0s
cronjob-3m-p-c-1580161080-6xndr   0/1     Pending             0          0s
cronjob-3m-p-c-1580161080-6xndr   0/1     ContainerCreating   0          0s
cronjob-3m-p-c-1580160960-279k5   1/1     Terminating         0          2m1s
cronjob-3m-p-c-1580160960-ddwc5   1/1     Terminating         0          2m1s
cronjob-3m-p-c-1580161080-6xndr   1/1     Running             0          4s
cronjob-3m-p-c-1580161080-98f84   1/1     Running             0          6s
cronjob-3m-p-c-1580160960-279k5   0/1     Terminating         0          2m32s
cronjob-3m-p-c-1580160960-ddwc5   0/1     Terminating         0          2m32s
cronjob-3m-p-c-1580160960-279k5   0/1     Terminating         0          2m33s
cronjob-3m-p-c-1580160960-279k5   0/1     Terminating         0          2m33s
cronjob-3m-p-c-1580160960-ddwc5   0/1     Terminating         0          2m34s
cronjob-3m-p-c-1580160960-ddwc5   0/1     Terminating         0          2m34s
```

W momencie startu kolejnego Job, pody z wcześniejszego są ubijane.
