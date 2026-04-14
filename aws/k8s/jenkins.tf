resource "kubernetes_deployment" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = "visual-dictionary"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "jenkins"
      }
    }

    template {
      metadata {
        labels = {
          app = "jenkins"
        }
      }

      spec {
        container {
          name  = "jenkins"
          image = "jenkins/jenkins:lts"

          port {
            container_port = 8080
          }

          port {
            container_port = 50000
          }

          volume_mount {
            name       = "jenkins-storage"
            mount_path = "/var/jenkins_home"
          }
        }

        volume {
          name = "jenkins-storage"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = "visual-dictionary"
  }

  spec {
    selector = {
      app = "jenkins"
    }

    port {
      name        = "http"
      port        = 8080
      target_port = 8080
    }

    port {
      name        = "agent"
      port        = 50000
      target_port = 50000
    }

    type = "LoadBalancer"
  }
}
