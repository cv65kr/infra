# Infrastructure

Simple infrastructure build with Terraform to create EKS cluster which supporting Istio.

VPC:
- Public and private subnets
- Internet gateway
- NAT gateway in each AZs

EKS:
- EKS managed node groups based on SPOT instances
- Fargate profiles configured for namespace without sidecar injection (TODO)
- Using public and private subnets

## Terraform

### Input
| Name                      | Default value                   | Description                                     |
|---------------------------|---------------------------------|-------------------------------------------------|
| environment               | stg                             | Environment e.g. staging, production            |
| dns_zone_name             | kk.dev                          |                                                 |
| kubernetes_cluster_name   | k8s                             | Name for the Kubernetes cluster                 |
| tags                      | {}                              | Default tags assigned to all AWS resources      |
| aws_region                | eu-west-1                       |                                                 |
| aws_profile               | playground                      | Profile used to deploy changes to AWS           |
| nodes_instances_sizes     | ["t3.medium"]                   |                                                 |
| auto_scale_options        | { min = 1 max = 2 desired = 1 } | Scale configuration for EKS managed node groups |
| helm_istio_version        | 1.15.3                          |                                                 |
| helm_prometheus_version   | 15.9.0                          |                                                 |
| helm_kiali_version        | 1.55.1                          |                                                 |
| helm_grafana_version      | 6.31.1                          |                                                 |
| helm_flagger_version      | 1.24.1                          |                                                 |
| helm_telepresence_version | 2.8.3                           |                                                 |
| release_version           | 1.0.0                           | Release version of your infrastructure          |

### Output
| Name            | Description                                           |
|-----------------|-------------------------------------------------------|
| kubeconfig_path | Path to kubeconfig default: kubeconfig_stg-k8s-kk-dev |

# CD
For progressive delivery operator it's used [https://flagger.app/](Flagger). You will find an example of usage canary pattern in [./podinfo/canary.yaml](Canary example).

# Development and debugging
For better DX, there is installed [https://www.telepresence.io/](Telepresence).

To start use it on your local computer, follow the [https://www.getambassador.io/docs/telepresence/latest/install/](instructions).

# Maintenance of your apps
TODO

# Dasboards
To add new dashboard to grafana, add your json to `tools/dasboards` catalog and run `make compress-grafana-dasboards` command. Command will minify jsons and put it in `tools/dashboards_compressed` catalog. Next step is creating `kubernetes_config_map` resource, you will find examples in `istio.tf`.

* [https://github.com/istio/istio/tree/master/manifests/addons/dashboards](https://github.com/istio/istio/tree/master/manifests/addons/dashboards)
* [https://github.com/fluxcd/flagger/tree/main/charts/grafana/dashboards](https://github.com/fluxcd/flagger/tree/main/charts/grafana/dashboards)

# Makefile
```
➜ make
run-dry                        Run terraform without deployment
run                            Run terraform with deployment
init                           Terraform init
plan                           Terraform plan
apply                          Terraform apply
test                           Terraform test
fix                            Fix style
apply-podinfo                  Apply podinfo to EKS
generate-cerfificate           Generate certificate e.g. make generate-cerfificate domain=yourdomain.com
compress-grafana-dasboards     Compress grafana dasboards
help                           Display this help message
```

# How to use
TODO

------
TODO:
- Route53
- mTLS
- Fargate for not sidecar proxy pods
- State in dynamodb 
- [https://infracost.io](infracost.io)
- Optional logging stack
