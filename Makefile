default: help

.PHONY: run-dry
run-dry: init plan ## Run terraform without deployment

.PHONY: init
init: ## Terraform init
	terraform init

.PHONY: plan
plan: ## Terraform plan
	terraform plan

.PHONY: test
test: ## Terraform test
	terraform test

.PHONY: fix
fix: ## Fix style
	terraform fmt -check -diff; \
	terraform fmt

.PHONY: help
help: ## Display this help message
	@cat $(MAKEFILE_LIST) | grep -e "^[a-zA-Z_\-]*: *.*## *" | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'