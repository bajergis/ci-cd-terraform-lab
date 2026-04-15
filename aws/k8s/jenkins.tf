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
          image = "397845934685.dkr.ecr.us-east-2.amazonaws.com/jenkins-custom:latest"

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