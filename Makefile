SHELL := /bin/bash
CURRENT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
ROLE_DIR=roles
EXTERNAL_ROLES_DIR=roles/external
INVENTORY_FILE=hosts


# We like colors
# From: https://coderwall.com/p/izxssa/colored-makefile-for-golang-projects
RED=`tput setaf 1`
GREEN=`tput setaf 2`
RESET=`tput sgr0`
YELLOW=`tput setaf 3`

# Add the following 'help' target to your Makefile
# And add help text after each target name starting with '\#\#'
.PHONY: help
help: ## This help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: all
all: setup

.PHONY: setup
setup: ## Build Jenkins Docker
	@echo "$(GREEN)==> Build Jenkins Docker$(RESET)"
	# docker pull jenkins/jenkins:lts
	# docker build -t jenkins .
	docker-compose -f tests/docker-compose.yml pull
	docker-compose -f tests/docker-compose.yml build
	virtualenv -p python3 .
	bin/pip install -r requirements.txt

.PHONY: start
start: ## Start Jenkins Docker
	@echo "$(GREEN)==> Start Jenkins Docker$(RESET)"
	docker run -p 8080:8080 -p 50000:50000 --env JAVA_OPTS="-Djenkins.install.runSetupWizard=false" jenkins

.PHONY: stop
stop: ## Start Jenkins Docker
	@echo "$(GREEN)==> Start Jenkins Docker$(RESET)"
	docker run -p 8080:8080 -p 50000:50000 --env JAVA_OPTS="-Djenkins.install.runSetupWizard=false" jenkins

.PHONY: test
test: ## Run Robot Tests
	@echo "$(GREEN)==> Run Robot Tests$(RESET)"
	bin/pytest tests

.PHONY: clean
clean: ## Remove old Virtualenv and creates a new one
	@echo "Clean"
	rm -rf bin lib include .Python
	make setup

.PHONY: get_roles
get_roles: ## Getting Roles from Ansible Galaxy
	@echo "$(GREEN)==> Getting roles from ansible-galaxy$(RESET)"
	ansible-galaxy install -r $(ROLE_DIR)/roles_requirements.yml --force --no-deps -p $(EXTERNAL_ROLES_DIR)
