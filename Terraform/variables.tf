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