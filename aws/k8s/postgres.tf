# Secret — holds the DB password, base64 encoded by Kubernetes
resource "kubernetes_secret" "postgres" {
  metadata {
    name      = "postgres-secret"
    namespace = "visual-dictionary"
  }
  data = {
    POSTGRES_PASSWORD = var.postgres_password
    POSTGRES_USER     = "vdict"
    POSTGRES_DB       = "visual_dictionary"
  }
}

# ConfigMap — non-sensitive config the Flask app reads
resource "kubernetes_config_map" "postgres" {
  metadata {
    name      = "postgres-config"
    namespace = "visual-dictionary"
  }
  data = {
    POSTGRES_HOST = "postgres-service"
    POSTGRES_PORT = "5432"
    POSTGRES_DB   = "visual_dictionary"
    POSTGRES_USER = "vdict"
  }
}

# StatefulSet — unlike a Deployment, pods get stable names (postgres-0)
# and each gets its own PVC automatically via volumeClaimTemplates
resource "kubernetes_stateful_set" "postgres" {
  metadata {
    name      = "postgres"
    namespace = "visual-dictionary"
  }
  spec {
    service_name = "postgres-service"
    replicas     = 1

    selector {
      match_labels = { app = "postgres" }
    }

    template {
      metadata {
        labels = { app = "postgres" }
      }
      spec {
        container {
          name  = "postgres"
          image = "postgres:16-alpine"

          port { container_port = 5432 }

          # Load password from Secret
          env_from {
            secret_ref { name = "postgres-secret" }
          }

          # Mount the PVC at the Postgres data directory
          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
            sub_path   = "postgres"  # important — avoids a lost+found issue with EBS
          }

          # Liveness/readiness so K8s knows when Postgres is actually ready
          liveness_probe {
            exec { command = ["pg_isready", "-U", "vdict"] }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
          readiness_probe {
            exec { command = ["pg_isready", "-U", "vdict"] }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }

    # This is the StatefulSet superpower — each pod gets its own PVC
    # K8s names them: postgres-data-postgres-0
    volume_claim_template {
      metadata { name = "postgres-data" }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "gp2"  # EBS on EKS
        resources {
          requests = { storage = "5Gi" }
        }
      }
    }
  }
}

# Headless service — required for StatefulSet DNS (postgres-0.postgres-service)
# Flask uses postgres-service:5432 which routes to the single pod
resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres-service"
    namespace = "visual-dictionary"
  }
  spec {
    selector   = { app = "postgres" }
    cluster_ip = "None"  # headless
    port {
      port        = 5432
      target_port = 5432
    }
  }
}
