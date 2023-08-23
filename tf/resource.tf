# resource "kubernetes_namespace" "green" {
#   metadata {
#     name = "green"
#   }
# }

# resource "kubernetes_namespace" "blue" {
#   metadata {
#     name = "blue"
#   }
# }

# # Pulls the image
# resource "docker_image" "ubuntu" {
#   name = "ubuntu:latest"
# }

# Create a container
# resource "docker_container" "foo" {
#   image = docker_image.ubuntu.image_id
#   name  = "foo"
#   command = ["sleep", "600"]
#   ports {
#     internal = 80
# 	external = 8080
#   }
#   destroy_grace_seconds = 30
# }
