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

video-render: ## Render compositions/<id> to output/<id>.mp4 (NAME=<id> [PROJECT=public/<id>|_private/<id>])
	@if [ -z "$(NAME)" ]; then echo "ERROR: NAME=<id> required"; exit 1; fi
	python3 orchestrator/scripts/03_render_video.py --composition $(NAME)$(if $(filter command line,$(origin PROJECT)), --project $(PROJECT))

video-test-hyperframes: video-up ## End-to-end smoke test (initialize + render)
	bash stacks/D-video/smoke_test_hyperframes.sh

video-test-manim: video-up ## End-to-end smoke test (Manim scene)
	bash stacks/D-video/smoke_test_manim.sh

manim-render: ## Render a Manim scene (SCENE=<file>:<class>)
	@if [ -z "$(SCENE)" ]; then echo "ERROR: SCENE=<file>:<class> required"; exit 1; fi
	@file=$$(echo $(SCENE) | cut -d: -f1); cls=$$(echo $(SCENE) | cut -d: -f2); \
	case "$$file" in public/*/*|_private/*/*) proj=$$(echo "$$file" | cut -d/ -f1-2);; *) proj="";; esac; \
	if [ -n "$$OUTDIR" ]; then host="$$OUTDIR"; elif [ -n "$$proj" ]; then host="$$proj/manim_scenes/media"; else host="manim_scenes/media"; fi; \
	case "$$host" in manim_scenes/*) cmedia="/manim/$${host#manim_scenes/}";; *) cmedia="/manim/$$host";; esac; \
	mkdir -p "$$host"; \
	docker exec puma_info_manim manim -qh --media_dir "$$cmedia" "/manim/$$file" $$cls

video-down: ## Stop both video services
	cd stacks/D-video && docker compose --profile video down

# === Group E · Publish ===

publish-build: ## Build WhisperX and uploader images
	cd stacks/E-publish && docker compose --profile publish build whisperx uploader

publish-up-whisper: gpu-available ## Start WhisperX (GPU)
	cd stacks/E-publish && docker compose --profile publish up -d whisperx
	@docker ps --filter "name=^puma_info_whisper$$" \
		--format "  {{.Names}}: {{.Status}}"

publish-up-uploader: ## Start uploader (CPU)
	cd stacks/E-publish && docker compose --profile publish up -d uploader
	@docker ps --filter "name=^puma_info_uploader$$" \
		--format "  {{.Names}}: {{.Status}}"

publish-test-whisper: publish-up-whisper ## Smoke test WhisperX end-to-end
	bash stacks/E-publish/smoke_test_whisper.sh

publish-test-uploader: publish-up-uploader ## Smoke test uploader (dry-run)
	bash stacks/E-publish/smoke_test_uploader.sh

publish-auth: publish-up-uploader ## Interactive OAuth flow (one-time)
	@if [ ! -f secrets/youtube_credentials.json ]; then \
		echo "ERROR: secrets/youtube_credentials.json missing."; \
		echo "Obtain it from Google Cloud Console (see stacks/E-publish/README.md)."; \
		exit 1; \
	fi
	docker exec -it puma_info_uploader python3 \
		/work/orchestrator/scripts/07_upload_youtube.py --auth-only

subs-%: publish-up-whisper ## Generate SRT for output/%.mp4 [PROJECT=public/<id>|_private/<id>]
	python3 orchestrator/scripts/04_generate_subtitles.py --video $*$(if $(filter command line,$(origin PROJECT)), --project $(PROJECT))

metadata-%: ## Generate metadata.json template for specs/%.json
	python3 orchestrator/scripts/06_generate_metadata.py --spec specs/$*.json

upload-dry-%: publish-up-uploader ## Dry-run YouTube upload (no API call)
	docker exec puma_info_uploader python3 \
		/work/orchestrator/scripts/07_upload_youtube.py --video $* --dry-run

upload-%: approvals/03_youtube_credentials_approved publish-up-uploader ## Real YouTube upload
	docker exec puma_info_uploader python3 \
		/work/orchestrator/scripts/07_upload_youtube.py --video $*

publish-down: ## Stop publish services
	cd stacks/E-publish && docker compose --profile publish down

approvals/03_youtube_credentials_approved:
	@echo "ERROR: YouTube credentials approval required."
	@echo "Steps:"
	@echo "  1. Set up Google Cloud project + enable YouTube Data API v3"
	@echo "  2. Download OAuth credentials.json to secrets/youtube_credentials.json"
	@echo "  3. Run 'make publish-auth' once to complete OAuth flow"
	@echo "  4. touch approvals/03_youtube_credentials_approved"
	@exit 1

# === Group F · Documents ===

docs-build: ## Build all Group F images (quarto, marp-mermaid, inkscape, libreoffice)
	cd stacks/F-documents && docker compose --profile documents build

docs-up: ## Start all docs services
	cd stacks/F-documents && docker compose --profile documents up -d
	@docker ps --filter "label=puma_info=true" \
		--filter "name=puma_info_(quarto|marp_mermaid|inkscape|libreoffice)" \
		--format "  {{.Names}}: {{.Status}}"

docs-test-quarto: docs-up ## Smoke test Quarto
	bash stacks/F-documents/smoke_test_quarto.sh

docs-test-marp: docs-up ## Smoke test Marp
	bash stacks/F-documents/smoke_test_marp.sh

docs-test-mermaid: docs-up ## Smoke test Mermaid
	bash stacks/F-documents/smoke_test_mermaid.sh

docs-test-inkscape: docs-up ## Smoke test Inkscape
	bash stacks/F-documents/smoke_test_inkscape.sh

docs-test-all: docs-test-quarto docs-test-marp docs-test-mermaid docs-test-inkscape docs-test-libreoffice ## Run all Group F smoke tests
	@echo "All Group F smoke tests PASSED."

quarto-render: docs-up ## Render a Quarto file (FILE=<path>, FORMAT=<pdf|html|docx>)
	@if [ -z "$(FILE)" ]; then echo "ERROR: FILE=<path> required"; exit 1; fi
	@case "$(FILE)" in public/*/*|_private/*/*) proj=$$(echo "$(FILE)" | cut -d/ -f1-2);; *) proj="";; esac; \
	outdir="$${OUTDIR:-$${proj:+$$proj/}output}"; mkdir -p "$$outdir"; \
	docker exec puma_info_quarto quarto render "/work/$(FILE)" --to "$${FORMAT:-pdf}" --output-dir "/work/$$outdir"

marp-render: docs-up ## Render a Marp deck (FILE=<path>, FORMAT=<pdf|pptx|html>)
	@if [ -z "$(FILE)" ]; then echo "ERROR: FILE=<path> required"; exit 1; fi
	@case "$(FILE)" in public/*/*|_private/*/*) proj=$$(echo "$(FILE)" | cut -d/ -f1-2);; *) proj="";; esac; \
	outdir="$${OUTDIR:-$${proj:+$$proj/}output}"; mkdir -p "$$outdir"; \
	docker exec puma_info_marp_mermaid marp "/work/$(FILE)" -o "/work/$$outdir/$$(basename $(FILE) .md).$${FORMAT:-pdf}" --allow-local-files

mermaid-render: docs-up ## Render a Mermaid diagram (FILE=<path>, FORMAT=<png|svg|pdf>)
	@if [ -z "$(FILE)" ]; then echo "ERROR: FILE=<path> required"; exit 1; fi
	@case "$(FILE)" in public/*/*|_private/*/*) proj=$$(echo "$(FILE)" | cut -d/ -f1-2);; *) proj="";; esac; \
	outdir="$${OUTDIR:-$${proj:+$$proj/}output}"; mkdir -p "$$outdir"; \
	docker exec puma_info_marp_mermaid mmdc -i "/work/$(FILE)" -o "/work/$$outdir/$$(basename $(FILE) .mmd).$${FORMAT:-png}" -p /puppeteer-config.json

inkscape-convert: docs-up ## Convert SVG (FILE=<path>, FORMAT=<png|pdf>)
	@if [ -z "$(FILE)" ]; then echo "ERROR: FILE=<path> required"; exit 1; fi
	@case "$(FILE)" in public/*/*|_private/*/*) proj=$$(echo "$(FILE)" | cut -d/ -f1-2);; *) proj="";; esac; \
	outdir="$${OUTDIR:-$${proj:+$$proj/}output}"; mkdir -p "$$outdir"; \
	docker exec puma_info_inkscape inkscape "/work/$(FILE)" --export-type="$${FORMAT:-png}" --export-filename="/work/$$outdir/$$(basename $(FILE) .svg).$${FORMAT:-png}"

pandoc-convert: docs-up ## Convert via Pandoc (bundled with Quarto) (FILE=<path>, FORMAT=<docx|html|epub>)
	@if [ -z "$(FILE)" ]; then echo "ERROR: FILE=<path> required"; exit 1; fi
	@case "$(FILE)" in public/*/*|_private/*/*) proj=$$(echo "$(FILE)" | cut -d/ -f1-2);; *) proj="";; esac; \
	outdir="$${OUTDIR:-$${proj:+$$proj/}output}"; mkdir -p "$$outdir"; \
	docker exec puma_info_quarto quarto pandoc "/work/$(FILE)" -o "/work/$$outdir/$$(basename $(FILE) .md).$${FORMAT:-docx}"

docs-down: ## Stop all docs services
	cd stacks/F-documents && docker compose --profile documents down

video-convert: video-up ## Convert/scale a video with ffmpeg (FILE=<path under compositions/ or output/>, FORMAT=<mp4|webm|mov>, RESOLUTION=<1080p|720p|4k>)
	@if [ -z "$(FILE)" ]; then echo "ERROR: FILE=<path> required"; exit 1; fi
	@case "$(FILE)" in public/*/*|_private/*/*) proj=$$(echo "$(FILE)" | cut -d/ -f1-2);; *) proj="";; esac; \
	outdir="$${OUTDIR:-$${proj:+$$proj/}output}"; mkdir -p "$$outdir"; \
	fmt="$${FORMAT:-mp4}"; \
	case "$$fmt" in \
		mp4|mov) codecs="-c:v libx264 -c:a aac";; \
		webm)    codecs="-c:v libvpx-vp9 -c:a libopus";; \
		*) echo "ERROR: FORMAT must be mp4|webm|mov"; exit 1;; \
	esac; \
	case "$${RESOLUTION:-}" in \
		1080p) scale="-vf scale=-2:1080";; \
		720p)  scale="-vf scale=-2:720";; \
		4k)    scale="-vf scale=-2:2160";; \
		"")    scale="";; \
		*) echo "ERROR: RESOLUTION must be 1080p|720p|4k"; exit 1;; \
	esac; \
	out="$$outdir/$$(basename "$(FILE)" | sed 's/\.[^.]*$$//').$$fmt"; \
	docker exec puma_info_hyperframes ffmpeg -y -i "/work/$(FILE)" $$scale $$codecs "/work/$$out"; \
	echo "Wrote $$out"

doc-ingest: docs-up ## Ingest a .docx (e.g. exported from Google Docs) to Markdown/HTML (FILE=<path under documents/>, FORMAT=<md|html>)
	@if [ -z "$(FILE)" ]; then echo "ERROR: FILE=<path> required"; exit 1; fi
	@case "$(FILE)" in public/*/*|_private/*/*) proj=$$(echo "$(FILE)" | cut -d/ -f1-2);; *) proj="";; esac; \
	docdir="$${OUTDIR:-$${proj:+$$proj/}documents}"; mkdir -p "$$docdir"; \
	docker exec puma_info_quarto sh -c 'cd "$$1" && quarto pandoc "$$2" -o "$$3" --extract-media=.' _ "/work/$$docdir" "/work/$(FILE)" "$$(basename "$(FILE)" .docx).$${FORMAT:-md}"

new-project: ## Scaffold a new project (NAME=<id> VISIBILITY=public|private)
	@if [ -z "$(NAME)" ]; then echo "ERROR: NAME=<id> required"; exit 1; fi
	@echo "$(NAME)" | grep -qE '^[^/]+$$' || { echo "ERROR: NAME must not contain '/'"; exit 1; }
	@case "$(VISIBILITY)" in public|private) ;; *) echo "ERROR: VISIBILITY must be public|private"; exit 1;; esac
	@if [ "$(VISIBILITY)" = "private" ]; then dest="_private/$(NAME)"; else dest="public/$(NAME)"; fi; \
	if [ -e "$$dest" ]; then echo "ERROR: $$dest already exists"; exit 1; fi; \
	mkdir -p "$$(dirname "$$dest")"; \
	cp -r templates/project "$$dest"; \
	echo "Created $$dest from templates/project"; \
	if [ "$(VISIBILITY)" = "private" ]; then \
		git init -q "$$dest"; \
		printf '\n## Private remote (optional)\n\nIndependent nested git, no remote. To version privately:\n\n    # git remote add origin <your-private-remote-url>   # never the public puma-info remote\n' >> "$$dest/README.md"; \
		echo "Initialized nested git in $$dest (no remote)"; \
	fi; \
	echo "Next: author $$dest/scripts/<video-id>/ from $$dest/scripts/_template; add a composition under $$dest/compositions/<video-id>/; render with PROJECT=$$dest"

slides-export: docs-up ## Export md/docx to editable .pptx via pandoc (FILE=<f.md|.docx>) [per-project OUTDIR]
	@if [ -z "$(FILE)" ]; then echo "ERROR: FILE=<path> required"; exit 1; fi
	@case "$(FILE)" in public/*/*|_private/*/*) proj=$$(echo "$(FILE)" | cut -d/ -f1-2);; *) proj="";; esac; \
	outdir="$${OUTDIR:-$${proj:+$$proj/}output}"; mkdir -p "$$outdir"; \
	name=$$(basename "$(FILE)"); name=$${name%.*}; \
	docker exec puma_info_quarto quarto pandoc "/work/$(FILE)" -o "/work/$$outdir/$$name.pptx"; \
	echo "Wrote $$outdir/$$name.pptx"

pptx-ingest: docs-up ## Import .pptx to pdf|html via LibreOffice (FILE=<f.pptx>, FORMAT=<pdf|html>) [per-project; pptx->md: html+pandoc bridge, see docs]
	@if [ -z "$(FILE)" ]; then echo "ERROR: FILE=<path> required"; exit 1; fi
	@case "$(FILE)" in public/*/*|_private/*/*) proj=$$(echo "$(FILE)" | cut -d/ -f1-2);; *) proj="";; esac; \
	docdir="$${OUTDIR:-$${proj:+$$proj/}documents}"; mkdir -p "$$docdir"; \
	docker exec puma_info_libreoffice soffice --headless -env:UserInstallation=file:///tmp/lo --convert-to "$${FORMAT:-html}" --outdir "/work/$$docdir" "/work/$(FILE)"; \
	echo "Wrote into $$docdir/"

docs-test-libreoffice: docs-up ## Smoke test LibreOffice (slides round-trip)
	bash stacks/F-documents/smoke_test_libreoffice.sh
