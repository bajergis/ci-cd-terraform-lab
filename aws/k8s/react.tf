resource "kubernetes_deployment" "react_app" {
  metadata {
    name      = "visual-dictionary-react"
    namespace = "visual-dictionary"
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "visual-dictionary-react" }
    }
    template {
      metadata {
        labels = { app = "visual-dictionary-react" }
      }
      spec {
        container {
          name  = "visual-dictionary-react"
          image = "397845934685.dkr.ecr.us-east-2.amazonaws.com/visual-dictionary-react:latest"
          port  { container_port = 80 }
        }
      }
    }
  }
}

resource "kubernetes_service" "react_app" {
  metadata {
    name      = "visual-dictionary-react"
    namespace = "visual-dictionary"
  }
  spec {
    selector = { app = "visual-dictionary-react" }
    type     = "LoadBalancer"
    port {
      port        = 80
      target_port = 80
    }
  }
}