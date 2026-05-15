resource "kubernetes_config_map" "app_config" {
  metadata {
    name = "app-config"
  }

  data = {
    PORT = var.backend_port
  }
}