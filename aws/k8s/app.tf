resource "kubernetes_deployment" "flask_app" {
  metadata {
    name      = "visual-dictionary"
    namespace = "visual-dictionary"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "visual-dictionary"
      }
    }

    template {
      metadata {
        labels = {
          app = "visual-dictionary"
        }
      }

      spec {
        container {
          name  = "visual-dictionary"
          image = "${var.ecr_repository_url}:latest"

          port {
            container_port = 5000
          }

          env {
            name = "UNSPLASH_ACCESS_KEY"
            value_from {
              secret_key_ref {
                name = "unsplash-secret"
                key  = "UNSPLASH_ACCESS_KEY"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "flask_app" {
  metadata {
    name      = "visual-dictionary"
    namespace = "visual-dictionary"
  }

  spec {
    selector = {
      app = "visual-dictionary"
    }

    port {
      port        = 80
      target_port = 5000
    }

    type = "LoadBalancer"
  }
}
