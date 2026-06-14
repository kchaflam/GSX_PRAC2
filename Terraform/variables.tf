variable "backend_image" {
  default = "kchaflam/backend-gsx:latest"
}

variable "nginx_image" {
  default = "kchaflam/nginx-gsx:latest"
}

variable "backend_port" {
  default = 8080
}

variable "nginx_port" {
  default = 80
}

variable "environments" {
  description = "Kubernetes environments managed by Terraform."

  type = map(object({
    namespace = string
    env_label = string
  }))

  default = {
    dev = {
      namespace = "development"
      env_label = "dev"
    }
    staging = {
      namespace = "staging"
      env_label = "staging"
    }
    prod = {
      namespace = "production"
      env_label = "prod"
    }
  }
}
