resource "kubernetes_deployment" "backend" {
  for_each = var.environments

  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.environment[each.key].metadata[0].name

    labels = {
      app = "backend"
      env = each.value.env_label
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "backend"
        env = each.value.env_label
      }
    }

    template {
      metadata {
        labels = {
          app = "backend"
          env = each.value.env_label
        }
      }

      spec {
        container {
          name  = "backend"
          image = var.backend_image

          port {
            container_port = var.backend_port
          }

          env {
            name = "PORT"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config[each.key].metadata[0].name
                key  = "PORT"
              }
            }
          }

          volume_mount {
            name       = "app-data"
            mount_path = "/data"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/"
              port = var.backend_port
            }

            initial_delay_seconds = 3
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/"
              port = var.backend_port
            }

            initial_delay_seconds = 10
            period_seconds        = 10
          }
        }

        volume {
          name = "app-data"

          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_deployment" "nginx" {
  for_each = var.environments

  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.environment[each.key].metadata[0].name

    labels = {
      app = "nginx"
      env = each.value.env_label
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginx"
        env = each.value.env_label
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
          env = each.value.env_label
        }
      }

      spec {
        container {
          name  = "nginx"
          image = var.nginx_image

          port {
            container_port = var.nginx_port
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/"
              port = var.nginx_port
            }

            initial_delay_seconds = 2
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/"
              port = var.nginx_port
            }

            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }
}
