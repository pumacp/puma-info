SHELL := /bin/bash
.DEFAULT_GOAL := help

# === Variables ===
NETWORK := puma_info_network
PROJECT := puma-info

# === Help ===
help: ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / \
		{printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# === Foundation ===
foundation-up: ## Create isolated Docker network for puma-info
	@docker network inspect $(NETWORK) >/dev/null 2>&1 || \
		docker network create \
			--driver bridge \
			--subnet 172.30.0.0/16 \
			--label puma_info=true \
			$(NETWORK)
	@docker network inspect $(NETWORK) --format '{{.Name}}: {{.IPAM.Config}}'

foundation-down: ## Remove the isolated Docker network (only if empty)
	@docker network rm $(NETWORK) 2>/dev/null || \
		echo "Network not empty or does not exist"

# === GPU semaphore ===
gpu-status: ## Show GPU usage by puma_info_* containers
	@nvidia-smi --query-gpu=memory.free,memory.used --format=csv
	@docker ps --filter "label=puma_info=true" \
		--filter "label=gpu=true" \
		--format "table {{.Names}}\t{{.Status}}"

gpu-release: ## Stop all puma_info GPU containers
	@docker ps --filter "label=puma_info=true" --filter "label=gpu=true" -q \
		| xargs -r docker stop
	@echo "GPU released"

# === Diagnostic ===
doctor: ## Verify environment health
	@echo "=== Network ==="
	@docker network inspect $(NETWORK) --format '{{.Name}}' \
		|| echo "MISSING: run 'make foundation-up'"
	@echo ""
	@echo "=== Existing PUMA resources (must be untouched) ==="
	@docker ps -a --filter "name=^puma_runner$$|^puma_dashboard$$|^puma_ollama$$" \
		--format "  {{.Names}}: {{.Status}}"
	@echo ""
	@echo "=== puma-info resources ==="
	@docker ps -a --filter "label=puma_info=true" \
		--format "  {{.Names}}: {{.Status}}"
	@echo ""
	@echo "=== Disk ==="
	@df -h ~/Projects/tfg/ | tail -1

# === Cleanup (safe — only puma_info-labeled resources) ===
cleanup: ## Remove ALL puma_info resources (containers, volumes, network)
	@read -p "This will remove all puma_info_* Docker resources. \
		Type 'yes' to continue: " confirm && [ "$$confirm" = "yes" ]
	@docker ps -a --filter "label=puma_info=true" -q | xargs -r docker rm -f
	@docker volume ls --filter "label=puma_info=true" -q | xargs -r docker volume rm
	@docker network rm $(NETWORK) 2>/dev/null || true
	@echo "Cleanup complete"
