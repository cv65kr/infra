ROOT_DIR = .
DASHBOARDS_DIR = ${ROOT_DIR}/tools/dashboards
DASHBOARDS_COMPRESSED_DIR = ${DASHBOARDS_DIR}_compressed

default: help

.PHONY: run-dry
run-dry: init plan ## Run terraform without deployment

.PHONY: run
run-dry: init plan apply ## Run terraform with deployment

.PHONY: init
init: ## Terraform init
	terraform init

.PHONY: plan
plan: ## Terraform plan
	terraform plan

.PHONY: apply
apply: ## Terraform apply
	terraform apply

.PHONY: test
test: ## Terraform test
	terraform test

.PHONY: fix
fix: ## Fix style
	terraform fmt -check -diff; \
	terraform fmt

.PHONY: apply-podinfo
apply-podinfo: ## Apply podinfo to EKS
	kubectl apply -f podinfo/app.yaml -f podinfo/gateway.yaml -f podinfo/hpa.yaml -f podinfo/canary.yaml -f podinfo/metric.yaml

.PHONY: compress-grafana-dasboards
compress-grafana-dasboards: ## Compress grafana dasboards
	@for file in $(DASHBOARDS_DIR)/* ; do \
		filename=`echo "$$file" | sed 's|^.*/||'`; \
        jq -r tostring $$file > ${DASHBOARDS_COMPRESSED_DIR}/$$filename; \
    done

.PHONY: help
help: ## Display this help message
	@cat $(MAKEFILE_LIST) | grep -e "^[a-zA-Z_\-]*: *.*## *" | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'