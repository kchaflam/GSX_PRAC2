output "backend_service" {
  value = kubernetes_service.backend.metadata[0].name
}

output "nginx_service" {
  value = kubernetes_service.nginx.metadata[0].name
}

output "node_port" {
  value = kubernetes_service.nginx.spec[0].port[0].node_port
}