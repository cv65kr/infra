# Infrastructure

**[WIP]** Project is still in progress

Simple infrastructure build with Terraform to create EKS cluster which supporting Istio.

VPC:
- Public and private subnets
- Internet gateway
- NAT gateway in each AZs

EKS:
- EKS managed node groups based on SPOT instances
- Fargate profiles configured for namespace without sidecar injection
- Using public and private subnets

**Limitations**
You cannot use AWS fargate for all pods - [https://github.com/aws/containers-roadmap/issues/682](https://github.com/aws/containers-roadmap/issues/682).

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
| telepresence_enabled      | true                            | Determine if telepresence should be in cluster  |

### Output
| Name            | Description                                           |
|-----------------|-------------------------------------------------------|

# CD
For progressive delivery operator it's used [Flagger](https://flagger.app/). You will find an example of usage canary pattern in [Canary example](podinfo/canary.yaml).

# Development and debugging
For better DX, there is installed [Telepresence](https://www.telepresence.io/).

To start use it on your local computer, follow the [instructions](https://www.getambassador.io/docs/telepresence/latest/install/).

# Maintenance of your apps

## Prefered structure of your app

Project should be placed in separate repository. The name of repository should follow the pattern `service-{language}-{project_name}` e.g. `service-go-ecommerce-order-orchestrator`.

Structure of catalogs:
```
service-go-project_name
│   README.md
│
└───source
│   │   your-application-file1.ext
│   │   your-application-file2.ext
|   |   ...
│   
└───charts
│    │   Chart.yaml
│    │   values.yaml
│    |   ...
│    
```

@TODO Add terraform resource which check your organisation repositories and based on repository name pattern upload all charts. This feature should have configuration option.


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
destroy                        Terraform destroy
test                           Terraform test
fix                            Fix style
update-kubeconfig              Create or update kubeconfig e.g. make update-kubeconfig profile=playground cluster=my-cluster
apply-podinfo                  Apply podinfo to EKS
generate-cerfificate           Generate certificate e.g. make generate-cerfificate domain=yourdomain.com
compress-grafana-dasboards     Compress grafana dasboards
help                           Display this help message
```

# How to use

Required tools:
- [Terraform](https://www.terraform.io/)
- [AWS cli](https://aws.amazon.com/cli/)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Telepresence](https://www.telepresence.io/)
- [JQ](https://stedolan.github.io/jq/)
- [GH](https://cli.github.com/)

Run in your cluster:
1. Configure your AWS profile
2. To run with deployment, use command:
```
make run
```
To run without deployment, use command:
```
make run-dry
```
3. Optionally you can deploy podinfo app for testing purposes (kubectl is required on your machine):
```
make apply-podinfo
```
4. Run `make update-kubeconfig profile=playground cluster=stg-k8s-kk-dev-eks` to store actual kubeconfig file, you can test if connection working properly by `kubectl get svc -n app` command.

------
@TODO:
- Route53
- mTLS
- State in dynamodb 
- [infracost.io](https://infracost.io)
- Optional logging stack
- Components settings adjustment
- Podinfo as helm + variable which decides if should be deployed or not
- Github projects detetion and auto deployment (section: Prefered structure of your app)
- SSM agent
- JWT auth