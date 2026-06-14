output "backend_service" {
  value = {
    for env, service in kubernetes_service.backend :
    env => "${service.metadata[0].namespace}/${service.metadata[0].name}"
  }
}

output "nginx_service" {
  value = {
    for env, service in kubernetes_service.nginx :
    env => "${service.metadata[0].namespace}/${service.metadata[0].name}"
  }
}

output "nginx_node_ports" {
  value = {
    for env, service in kubernetes_service.nginx :
    env => service.spec[0].port[0].node_port
  }
}
