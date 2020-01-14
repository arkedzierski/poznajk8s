# Demo skalowanie aplikacji z HPA

1. Instalacja metrics-server z kubernetes-sigs (https://github.com/kubernetes-sigs/metrics-server) zgodnie z README.md

    * Przygotowanie minikube
    
    ```bash
    $ minikube addons disable metrics-server

    $ minikube delete
    
    $ minikube start --extra-config=kubelet.authentication-token-webhook=true --memory 4096
    ```
    
    * Clone repo i z tego poziomu

    ```bash
    $ kubectl create -f deploy/1.8+/
    ```

    * Dodanie flag do metric-server do args deployment

    ```bash
    $ kubectl edit deploy -n kube-system metrics-server
    ```

    ```
    args:
    - --kubelet-insecure-tls
    - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
    ```

2. Tworzymy metric-server i autoscaler

    ```bash
    $ kubectl run ll --image=k8s.gcr.io/hpa-example --requests=cpu=200m --expose --port=80

    $ kubectl autoscale deployment ll --cpu-percent=50 --min=1 --max=10
    ```

3. Sprawdzamy poprawność utworzenia autoscale z deploymentem (HPA)

    ```bash
    $ kubectl describe hpa

    Name:                                                  ll
    Namespace:                                             default
    Labels:                                                <none>
    Annotations:                                           <none>
    CreationTimestamp:                                     Tue, 14 Jan 2020 20:53:05 +0100
    Reference:                                             Deployment/ll
    Metrics:                                               ( current / target )
    resource cpu on pods  (as a percentage of request):  <unknown> / 50%
    Min replicas:                                          1
    Max replicas:                                          10
    Deployment pods:                                       1 current / 0 desired
    Conditions:
    Type           Status  Reason                   Message
    ----           ------  ------                   -------
    AbleToScale    True    SucceededGetScale        the HPA controller was able to get the targets current scale
    ScalingActive  False   FailedGetResourceMetric  the HPA was unable to compute the replica count: unable to get metrics for resource cpu: no metrics returned from resource metrics API
    Events:
    Type     Reason                        Age               From                       Message
    ----     ------                        ----              ----                       -------
    Warning  FailedGetResourceMetric       4s (x2 over 19s)  horizontal-pod-autoscaler  unable to get metrics for resource cpu: no metrics returned from resource metrics API
    Warning  FailedComputeMetricsReplicas  4s (x2 over 19s)  horizontal-pod-autoscaler  invalid metrics (1 invalid out of 1), first error is: failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
    ```

    ```bash
    $ kubectl get hpa

    NAME   REFERENCE       TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
    ll     Deployment/ll   <unknown>/50%   1         10        1          19s
    ```

    ```bash
    $ kubectl top pods
    
    NAME                 CPU(cores)   MEMORY(bytes)
    ll-59ff7b546-vjrrd   971m         12Mi
    ```

    ```bash
    $ kubectl get svc

    NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
    kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP   31m
    ll           ClusterIP   10.101.3.215   <none>        80/TCP    5m56s
    ```

4. Sprawdzamy działanie HPA

    * Toworzymy pod który będzie obciążał nasz deployment ll

    ```bash
    $ winpty kubectl run bb --image=busybox --restart=Never --rm -it -- sh

    If you dont see a command prompt, try pressing enter.
    / # while true; do wget -q -O- http://ll.default.svc.cluster.local; done
    ```

    * Obserwujemy działanie HPA po uruchomieniu do zatrzymania i chwile dłużej

    `deployment`

    ```bash
    $ kubectl get deployment ll -w

    NAME   READY   UP-TO-DATE   AVAILABLE   AGE
    ll     10/10   10           10          30m
    ll     10/1    10           10          36m
    ll     10/1    10           10          36m
    ll     1/1     1            1           36m
    ```

    `hpa`

    ```bash
    $ kubectl get hpa -w

    NAME   REFERENCE       TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
    ll     Deployment/ll   55%/50%   1         10        10         28m
    ll     Deployment/ll   46%/50%   1         10        10         28m
    ll     Deployment/ll   0%/50%    1         10        10         29m
    ll     Deployment/ll   0%/50%    1         10        10         33m
    ll     Deployment/ll   0%/50%    1         10        10         34m
    ll     Deployment/ll   0%/50%    1         10        1          34m
    ```

    Wniosek: HPA utrzymuje stworzone pody (dla tego testu) przez ok 6-7 min po spadku obciążenia na wypadek tylko chwilowego zaprzestania

    4. Dla tryby deklaratywnego poniżej zamieszczono przykładowe YAMLe:

`HPA`

```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache
spec:
  maxReplicas: 10
  minReplicas: 1
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  targetCPUUtilizationPercentage: 50
status:
  currentReplicas: 0
  desiredReplicas: 0
```

`Service i Deployment`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: php-apache
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    run: php-apache
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    run: php-apache
  name: php-apache
spec:
  replicas: 1
  selector:
    matchLabels:
      run: php-apache
  template:
    metadata:
      labels:
        run: php-apache
    spec:
      containers:
      - image: k8s.gcr.io/hpa-example
        name: php-apache
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 200m
```


