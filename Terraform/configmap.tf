resource "kubernetes_config_map" "app_config" {
  for_each = var.environments

  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.environment[each.key].metadata[0].name
  }

  data = {
    PORT = var.backend_port
  }
}
