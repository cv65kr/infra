provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["--profile", var.aws_profile, "eks", "get-token", "--cluster-name", module.eks.cluster_id]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["--profile", var.aws_profile, "eks", "get-token", "--cluster-name", module.eks.cluster_id]
    }
  }
}

provider "tls" {
}

## Init istio base 
resource "kubernetes_namespace" "namespace_istio-system" {
  metadata {
    name = "istio-system"
  }
  depends_on = [module.eks.cluster_id]
}

resource "helm_release" "istio-base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  version    = var.helm_istio_version
  namespace  = kubernetes_namespace.namespace_istio-system.id
  depends_on = [module.eks.cluster_id]
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = var.helm_istio_version
  namespace  = kubernetes_namespace.namespace_istio-system.id
  depends_on = [module.eks.cluster_id, helm_release.istio-base]
}

### Subsitute for --wait parameter
resource "null_resource" "istiod-delay" {
  depends_on = [module.eks.cluster_id, helm_release.istiod]
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
  depends_on = [module.eks.cluster_id, null_resource.istiod-delay]
}

resource "helm_release" "istio-gateway" {
  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = var.helm_istio_version
  namespace  = kubernetes_namespace.namespace_istio-ingress.id
  depends_on = [module.eks.cluster_id, helm_release.istio-base, helm_release.istiod]
  timeout    = 400
}

## Tools namespace (disabled istio injected, delegated to Fargate profile)
resource "kubernetes_namespace" "namespace_tools" {
  metadata {
    name = "tools"
  }
  depends_on = [module.eks.cluster_id]
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = var.helm_prometheus_version
  namespace  = kubernetes_namespace.namespace_tools.id
  depends_on = [module.eks.cluster_id, kubernetes_namespace.namespace_tools]
  timeout    = 400
  values = [
    "${file("${path.module}/tools/values-prometheus.yaml")}"
  ]
}

resource "helm_release" "kiali" {
  name       = "kiali"
  repository = "https://kiali.org/helm-charts"
  chart      = "kiali-server"
  version    = var.helm_kiali_version
  namespace  = kubernetes_namespace.namespace_tools.id
  depends_on = [module.eks.cluster_id, kubernetes_namespace.namespace_tools]
  timeout    = 400
  set {
    name  = "deployment.image_version"
    value = "v1.55"
  }

  set {
    name  = "nameOverride"
    value = "kiali"
  }

  set {
    name  = "fullnameOverride"
    value = "kiali"
  }

  values = [
    "${file("${path.module}/tools/values-kiali.yaml")}"
  ]
}

resource "kubernetes_config_map" "istio-grafana-dashboards" {
  metadata {
    name      = "istio-grafana-dashboards"
    namespace = kubernetes_namespace.namespace_tools.id
  }

  data = {
    "pilot-dashboard.json"             = "${file("${path.module}/tools/dashboards_compressed/pilot-dashboard.json")}"
    "istio-performance-dashboard.json" = "${file("${path.module}/tools/dashboards_compressed/istio-performance-dashboard.json")}"
  }

  depends_on = [module.eks.cluster_id]
}

resource "kubernetes_config_map" "istio-services-grafana-dashboards" {
  metadata {
    name      = "istio-services-grafana-dashboards"
    namespace = kubernetes_namespace.namespace_tools.id
  }

  data = {
    "istio-workload-dashboard.json"  = "${file("${path.module}/tools/dashboards_compressed/istio-workload-dashboard.json")}"
    "istio-service-dashboard.json"   = "${file("${path.module}/tools/dashboards_compressed/istio-service-dashboard.json")}"
    "istio-mesh-dashboard.json"      = "${file("${path.module}/tools/dashboards_compressed/istio-mesh-dashboard.json")}"
    "istio-extension-dashboard.json" = "${file("${path.module}/tools/dashboards_compressed/istio-extension-dashboard.json")}"
  }

  depends_on = [module.eks.cluster_id]
}

resource "kubernetes_config_map" "istio-services-grafana-flagger-dashboards" {
  metadata {
    name      = "istio-services-grafana-flagger-dashboards"
    namespace = kubernetes_namespace.namespace_tools.id
  }

  data = {
    "flagger-istio-dashboard.json" = "${file("${path.module}/tools/dashboards_compressed/flagger-istio-dashboard.json")}"
    "flagger-envoy-dashboard.json" = "${file("${path.module}/tools/dashboards_compressed/flagger-envoy-dashboard.json")}"
  }

  depends_on = [module.eks.cluster_id]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = var.helm_grafana_version
  namespace  = kubernetes_namespace.namespace_tools.id
  depends_on = [
    module.eks.cluster_id,
    kubernetes_namespace.namespace_tools,
    kubernetes_config_map.istio-grafana-dashboards,
    kubernetes_config_map.istio-services-grafana-dashboards
  ]
  timeout = 400
  values = [
    "${file("${path.module}/tools/values-grafana.yaml")}"
  ]
}

resource "helm_release" "flagger" {
  name       = "flagger"
  repository = "https://flagger.app"
  chart      = "flagger"
  version    = var.helm_flagger_version
  namespace  = kubernetes_namespace.namespace_tools.id
  depends_on = [module.eks.cluster_id, kubernetes_namespace.namespace_tools]
  timeout    = 400
  values = [
    "${file("${path.module}/tools/values-flagger.yaml")}"
  ]
}

resource "helm_release" "telepresence" {
  count = var.telepresence_enabled ? 1 : 0

  name       = "traffic-manager"
  repository = "https://getambassador.io"
  chart      = "telepresence"
  version    = var.helm_telepresence_version
  namespace  = kubernetes_namespace.namespace_tools.id
  depends_on = [module.eks.cluster_id, kubernetes_namespace.namespace_tools]
  timeout    = 400
  values = [
    "${file("${path.module}/tools/values-telepresence.yaml")}"
  ]
}

## App namespace
resource "kubernetes_namespace" "namespace_app" {
  metadata {
    labels = {
      "istio-injection" = "enabled"
    }
    name = "app"
  }
  depends_on = [module.eks.cluster_id]
}