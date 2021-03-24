data "kubernetes_service_account" "vault_auth" {
  depends_on = [helm_release.vault]
  metadata {
    name = "vault"
  }
}

data "kubernetes_secret" "vault_auth" {
  depends_on = [helm_release.vault]
  metadata {
    name = data.kubernetes_service_account.vault_auth.default_secret_name
  }
}

resource "vault_auth_backend" "kubernetes" {
  depends_on = [helm_release.vault]
  type       = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  depends_on         = [helm_release.vault]
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = local.kubernetes_host
  kubernetes_ca_cert = data.kubernetes_secret.vault_auth.data["ca.crt"]
  token_reviewer_jwt = data.kubernetes_secret.vault_auth.data.token
}

resource "vault_kubernetes_auth_backend_role" "product" {
  depends_on                       = [helm_release.vault]
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "product"
  bound_service_account_names      = ["product"]
  bound_service_account_namespaces = ["default"]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.product.name]
}

resource "helm_release" "vault" {
  name = "vault"

  chart = "https://github.com/hashicorp/vault-helm/archive/${var.vault_helm_version}.tar.gz"

  set {
    name  = "injector.enabled"
    value = "true"
  }

  set {
    name  = "injector.externalVaultAddr"
    value = var.vault_private_address
  }
}