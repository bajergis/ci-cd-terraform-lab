resource "kubernetes_secret" "unsplash" {
  metadata {
    name      = "unsplash-secret"
    namespace = "visual-dictionary"
  }

  data = {
    UNSPLASH_ACCESS_KEY = var.unsplash_access_key
  }
}
