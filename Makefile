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
	@df -h . | tail -1

# === Cleanup (safe — only puma_info-labeled resources) ===
cleanup: ## Remove ALL puma_info resources (containers, volumes, network)
	@read -p "This will remove all puma_info_* Docker resources. \
		Type 'yes' to continue: " confirm && [ "$$confirm" = "yes" ]
	@docker ps -a --filter "label=puma_info=true" -q | xargs -r docker rm -f
	@docker volume ls --filter "label=puma_info=true" -q | xargs -r docker volume rm
	@docker network rm $(NETWORK) 2>/dev/null || true
	@echo "Cleanup complete"

# === Group B · Translation ===

translation-up: ## Start Group B services (ollama + libretranslate)
	cd stacks/B-translation && \
		docker compose --profile translation up -d ollama libretranslate
	@docker ps --filter "label=puma_info=true" \
		--format "  {{.Names}}: {{.Status}}"

translation-pull-models: ## Pull qwen2.5:7b into puma_info_ollama (NOT the PUMA one)
	docker exec puma_info_ollama ollama pull qwen2.5:7b
	docker exec puma_info_ollama ollama pull qwen2.5:3b
	docker exec puma_info_ollama ollama list

translation-smoke-test: ## End-to-end smoke test on a synthetic 1-page PDF
	bash stacks/B-translation/smoke_test.sh

translation-run: approvals/01_pdf_translation_approved ## Translate every PDF in input_es/
	python3 orchestrator/scripts/05_translate_pdfs.py

translation-down: ## Stop Group B services (containers only, models persist)
	cd stacks/B-translation && docker compose --profile translation down

approvals/01_pdf_translation_approved:
	@echo "ERROR: human approval required before batch translation."
	@echo "       Create this marker file manually after verifying outputs:"
	@echo "       touch approvals/01_pdf_translation_approved"
	@exit 1

# === Group C · Voice ===

gpu-available: ## Fail if a puma_info_* GPU container is currently running
	@running=$$(docker ps --filter "label=puma_info=true" \
		--filter "label=gpu=true" -q | wc -l); \
	if [ "$$running" -gt "0" ]; then \
		echo "ERROR: another puma_info_* GPU service is running."; \
		docker ps --filter "label=puma_info=true" --filter "label=gpu=true" \
			--format "  {{.Names}}: {{.Status}}"; \
		echo "Run 'make gpu-release' first."; \
		exit 1; \
	fi

voice-build: ## Build Piper and XTTS images
	cd stacks/C-voice && docker compose --profile voice build piper xtts

voice-up-piper: ## Start Piper (CPU only)
	cd stacks/C-voice && docker compose --profile voice up -d piper
	@docker ps --filter "name=^puma_info_piper$$" \
		--format "  {{.Names}}: {{.Status}}"

voice-up-xtts: gpu-available ## Start XTTS v2 (GPU)
	cd stacks/C-voice && docker compose --profile voice up -d xtts
	@docker ps --filter "name=^puma_info_xtts$$" \
		--format "  {{.Names}}: {{.Status}}"

voice-test-piper: voice-up-piper ## Smoke test Piper end-to-end (synthesize and verify)
	bash stacks/C-voice/smoke_test_piper.sh

voice-test-xtts: voice-up-xtts ## Verify XTTS v2 starts and model loads
	bash stacks/C-voice/smoke_test_xtts.sh

voice-down: ## Stop all Group C services
	cd stacks/C-voice && docker compose --profile voice down

# === Group D · Video ===

video-build: ## Build HyperFrames and Manim images
	cd stacks/D-video && docker compose --profile video build hyperframes manim

video-up: ## Start both video services
	cd stacks/D-video && docker compose --profile video up -d hyperframes manim
	@docker ps --filter "label=puma_info=true" --filter "name=puma_info_(hyperframes|manim)" \
		--format "  {{.Names}}: {{.Status}}"

video-install-skills: video-up ## Install HyperFrames skills into compositions/_template/
	mkdir -p compositions/_template
	docker exec puma_info_hyperframes bash -c \
		"cd /work/compositions/_template && GIT_LFS_SKIP_SMUDGE=1 npx skills add heygen-com/hyperframes --yes"
	@echo "Skills installed. Use 'make video-new-composition NAME=<id>' to clone."

video-new-composition: ## Clone the skills template to a new composition (NAME=<id>)
	@if [ -z "$(NAME)" ]; then \
		echo "ERROR: NAME=<video-id> required"; exit 1; \
	fi
	@if [ -d "compositions/$(NAME)" ]; then \
		echo "ERROR: compositions/$(NAME) already exists"; exit 1; \
	fi
	@if [ ! -d "compositions/_template" ]; then \
		echo "ERROR: run 'make video-install-skills' first"; exit 1; \
	fi
	cp -r compositions/_template "compositions/$(NAME)"
	@echo "Created compositions/$(NAME)"

video-preview: ## Launch HyperFrames preview server (NAME=<id>)
	@if [ -z "$(NAME)" ]; then echo "ERROR: NAME=<id> required"; exit 1; fi
	docker exec -d puma_info_hyperframes bash -c \
		"cd /work/compositions/$(NAME) && npx hyperframes preview --port 3000"
	@echo "Preview at http://localhost:3001"

video-render: ## Render compositions/<id> to output/<id>.mp4 (NAME=<id>)
	@if [ -z "$(NAME)" ]; then echo "ERROR: NAME=<id> required"; exit 1; fi
	python3 orchestrator/scripts/03_render_video.py --composition $(NAME)

video-test-hyperframes: video-up ## End-to-end smoke test (initialize + render)
	bash stacks/D-video/smoke_test_hyperframes.sh

video-test-manim: video-up ## End-to-end smoke test (Manim scene)
	bash stacks/D-video/smoke_test_manim.sh

manim-render: ## Render a Manim scene (SCENE=<file>:<class>)
	@if [ -z "$(SCENE)" ]; then echo "ERROR: SCENE=<file>:<class> required"; exit 1; fi
	@file=$$(echo $(SCENE) | cut -d: -f1); cls=$$(echo $(SCENE) | cut -d: -f2); \
	docker exec puma_info_manim manim -qh "/manim/$$file" $$cls

video-down: ## Stop both video services
	cd stacks/D-video && docker compose --profile video down
