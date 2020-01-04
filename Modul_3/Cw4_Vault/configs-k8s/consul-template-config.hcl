vault {
  renew_token = false
  vault_agent_token_file = "/home/vault/.vault-token"
  retry {
    backoff = "1s"
  }
}

template {
  destination = "/etc/secrets/secrets.json"
  contents = <<EOH
  {
      {{- with secret "secret/myapp/config" }}
      "username": "{{ .Data.username }}",
      "password": "{{ .Data.password }}"
      {{ end }}
  }
  EOH
}
