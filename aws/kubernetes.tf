resource "kubernetes_namespace" "app" {
  metadata {
    name = "visual-dictionary"
  }

  depends_on = [module.eks]
}
