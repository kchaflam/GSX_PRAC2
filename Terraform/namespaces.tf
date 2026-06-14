resource "kubernetes_namespace" "environment" {
  for_each = var.environments

  metadata {
    name = each.value.namespace
  }
}
