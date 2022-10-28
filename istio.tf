provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  config_path            = local_file.kubeconfig.filename
  #token = var.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    config_path            = local_file.kubeconfig.filename
    #token = var.token
  }
}

## Init istio base 
resource "kubernetes_namespace" "namespace_istio-system" {
  metadata {
    name = "istio-system"
  }
  depends_on = [local_file.kubeconfig]
}

resource "helm_release" "istio-base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  version    = var.helm_istio_version
  namespace  = kubernetes_namespace.namespace_istio-system.id
  depends_on = [local_file.kubeconfig]
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = var.helm_istio_version
  namespace  = kubernetes_namespace.namespace_istio-system.id
  depends_on = [local_file.kubeconfig, helm_release.istio-base]
}

### Subsitute for --wait parameter
resource "null_resource" "istiod-delay" {
  depends_on = [local_file.kubeconfig, helm_release.istiod]
  provisioner "local-exec" {
    command = "sleep 100"
  }
}

## Install ingress gateway
resource "kubernetes_namespace" "namespace_istio-ingress" {
  metadata {
    labels = {
      "istio-injection" = "enabled"
    }
    name = "istio-ingress"
  }
  depends_on = [local_file.kubeconfig, null_resource.istiod-delay]
}

resource "helm_release" "istio-gateway" {
  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = var.helm_istio_version
  namespace  = kubernetes_namespace.namespace_istio-ingress.id
  depends_on = [local_file.kubeconfig, helm_release.istio-base, helm_release.istiod]
  timeout    = 40
}
