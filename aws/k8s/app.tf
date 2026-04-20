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

        init_container {
          name = "wait-for-deps"
          image = "busybox:1.36"
          command = ["sh", "-c", "until nc -z postgres-service 5432; do echo waiting for postgres; sleep 2; done && until nc -z redis-service 6379; do echo waiting for redis; sleep 2; done"]
        }

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

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = "postgres-secret"
                key = "POSTGRES_PASSWORD"
              }
            }
          }

          env {
            name = "POSTGRES_HOST"
            value_from {
              config_map_key_ref {
                name = "postgres-config"
                key = "POSTGRES_HOST"
              }
            }
          }
          env {
            name = "POSTGRES_PORT"
            value_from {
              config_map_key_ref {
                name = "postgres-config"
                key = "POSTGRES_PORT"
              }
            }
          }
          env {
            name = "POSTGRES_DB"
            value_from {
              config_map_key_ref {
                name = "postgres-config"
                key = "POSTGRES_DB"
              }
            }
          }
          env {
            name = "POSTGRES_USER"
            value_from {
              config_map_key_ref {
                name = "postgres-config"
                key = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "REDIS_URL"
            value = "redis://redis-service:6379"
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

    type = "ClusterIP"
  }
}
