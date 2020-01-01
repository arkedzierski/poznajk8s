# HashiCorp Vault – Ćwiczenia

Na podstawie demo i materiałów z poprzedniej lekcji wykorzystaj Vault do przekazania konfiguracji.
W swoim Pod wygeneruj plik konfiguracyjny typu json lub xml ze secretami z Vault.

1. Tworzymy poda z obrazem Vault (dla potrzeb ćwiczena uruchamiamy z opcją `-dev`)

```bash
kubectl create -f vault.yaml
```

2. Wyciągamy token z poda i wstawiamy w zmienną środowiskową

```bash
kubectl logs vault | grep Token

Root Token: s.IzZu64wRu6iUI4ucqnn7cGLA
```

```bash
export VAULT_TOKEN=s.IzZu64wRu6iUI4ucqnn7cGLA
```

3. Ustawiamy zmienną środowiskową z adresem Vault oraz usdotepniamy go przez port-forward

```bash
export VAULT_ADDR=http://127.0.0.1:8200
```

```bash
kubectl port-forward vault 8200 &
```

4. Utworzenie konta serwisowego (do odczytu danych z kubernetessa)

```bash
kubectl apply --filename vault-auth-service-account.yml
```

5. Stworzenie polityki dostępowej do secretów w Vault

```bash
vault policy write myapp-kv-ro myapp-kv-ro.hcl
```

6. Utworzenie secretu do którego będziemy się dostawać (chwilę trzeba poczekać przed dodaniem)

```bash
vault secrets enable -path=myapp kv
```

```bash
vault kv put myapp/config username='appuser' password='suP3rsec(et!' ttl='30s'
```

7. Ustawienie pozostałych zmiennych środowiskowych

* pobranie konta serwisowego:

```bash
export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
```

* wyciągniecie samego token

```bash
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
```

* klucz publiczny certyfikatu

```bash
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
```

* adres hosta

```bash
export K8S_HOST=kubernetes.docker.internal
```

8. Kończymy konfigurację Vault - włączamy uwierzytelnianie, dostęp do tokenów oraz stworzenie roli

```bash
vault auth enable kubernetes
```

```bash
vault write auth/kubernetes/config token_reviewer_jwt="$SA_JWT_TOKEN" kubernetes_host="https://$K8S_HOST:6443" kubernetes_ca_cert="$SA_CA_CRT"
```

```bash
vault write auth/kubernetes/role/example bound_service_account_names=demo-pod bound_service_account_namespaces=default policies=myapp-kv-ro ttl=24h
```
