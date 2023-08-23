
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "rancher-desktop"
}

# provider "docker" {
#   host = "unix:///var/run/docker.sock"
# }

