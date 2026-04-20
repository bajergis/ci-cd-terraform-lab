resource "kubernetes_stateful_set" "redis" {
  metadata {
    name      = "redis"
    namespace = "visual-dictionary"
  }
  spec {
    service_name = "redis-service"
    replicas     = 1

    selector {
      match_labels = { app = "redis" }
    }

    template {
      metadata {
        labels = { app = "redis" }
      }
      spec {
        container {
          name  = "redis"
          image = "redis:7-alpine"
          port  { container_port = 6379 }

          volume_mount {
            name       = "redis-data"
            mount_path = "/data"
          }

          liveness_probe {
            exec { command = ["redis-cli", "ping"] }
            initial_delay_seconds = 15
            period_seconds        = 10
          }
          readiness_probe {
            exec { command = ["redis-cli", "ping"] }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }

    volume_claim_template {
      metadata { name = "redis-data" }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "gp2"
        resources {
          requests = { storage = "1Gi" }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name      = "redis-service"
    namespace = "visual-dictionary"
  }
  spec {
    selector   = { app = "redis" }
    cluster_ip = "None"  # headless, same pattern as postgres
    port {
      port        = 6379
      target_port = 6379
    }
  }
}
