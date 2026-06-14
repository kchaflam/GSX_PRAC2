resource "kubernetes_service" "backend" {
  for_each = var.environments

  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.environment[each.key].metadata[0].name
  }

  spec {
    selector = {
      app = "backend"
      env = each.value.env_label
    }

    port {
      port        = var.backend_port
      target_port = var.backend_port
    }
  }
}

resource "kubernetes_service" "nginx" {
  for_each = var.environments

  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.environment[each.key].metadata[0].name
  }

  spec {
    selector = {
      app = "nginx"
      env = each.value.env_label
    }

    type = "NodePort"

    port {
      port        = var.nginx_port
      target_port = var.nginx_port
    }
  }
}
