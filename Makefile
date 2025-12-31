PAK_NAME := $(shell jq -r .name pak.json)
PAK_TYPE := $(shell jq -r .type pak.json)
PAK_FOLDER := $(shell echo $(PAK_TYPE) | cut -c1)$(shell echo $(PAK_TYPE) | tr '[:upper:]' '[:lower:]' | cut -c2-)s

PUSH_SDCARD_PATH ?= /mnt/SDCARD
PUSH_PLATFORM ?= tg5040

ARCHITECTURES := arm64
PLATFORMS := tg5040

MINUI_PRESENTER_VERSION := 0.4.0
PAKUI_VERSION := 1.3.1
MINUI_BASH_VERSION := 1.0.0

clean:
	rm -f bin/*/minui-presenter* || true
	rm -f bin/*/bash* || true
	rmdir bin/arm64 || true
	rmdir bin/tg5040 || true
	rm -rf BitPal || true

bump-version:
	jq '.version = "$(RELEASE_VERSION)"' pak.json > pak.json.tmp
	mv pak.json.tmp pak.json

build: $(foreach platform,$(PLATFORMS),bin/$(platform)/minui-presenter) $(foreach arch,$(ARCHITECTURES),bin/$(arch)/bash) BitPal

bin/%/minui-presenter:
	mkdir -p bin/$*
	curl -f -o bin/$*/minui-presenter -sSL https://github.com/josegonzalez/minui-presenter/releases/download/$(MINUI_PRESENTER_VERSION)/minui-presenter-$*
	chmod +x bin/$*/minui-presenter

bin/arm64/bash:
	mkdir -p bin/arm64
	curl -f -o bin/arm64/bash -sSL "https://github.com/pobega/minui-bash/releases/download/$(MINUI_BASH_VERSION)/minui-bash-aarch64"
	chmod +x bin/arm64/bash
	curl -sSL -o bin/arm64/bash.LICENSE "https://github.com/pobega/minui-bash/raw/refs/heads/main/bash.LICENSE"

BitPal:
	@if [ ! -d /tmp/bitpal_original ]; then \
		echo "Downloading PakUI..."; \
		curl -f -sSL -o /tmp/pakui_temp.zip https://github.com/tenlevels/PakUI/releases/download/v$(PAKUI_VERSION)/PakUI_v$(PAKUI_VERSION).zip; \
		mkdir -p /tmp/pakui_temp; \
		unzip -o /tmp/pakui_temp.zip "Roms/*" -d /tmp/pakui_temp; \
		mv "/tmp/pakui_temp/Roms/0) BitPal (BITPAL)" "/tmp/bitpal_original"; \
		rm -rf /tmp/pakui_temp.zip /tmp/pakui_temp; \
	fi
	cp -r /tmp/bitpal_original BitPal

save-patches:
	@mkdir -p patches
	@if [ -d BitPal ]; then \
		if [ ! -d "/tmp/bitpal_original" ]; then \
			echo "Downloading PakUI..."; \
			curl -f -sSL -o /tmp/pakui_temp.zip https://github.com/tenlevels/PakUI/releases/download/v$(PAKUI_VERSION)/PakUI_v$(PAKUI_VERSION).zip; \
			mkdir -p /tmp/pakui_temp; \
			unzip -o /tmp/pakui_temp.zip "Roms/*" -d /tmp/pakui_temp; \
			mv "/tmp/pakui_temp/Roms/0) BitPal (BITPAL)" "/tmp/bitpal_original"; \
			rm -rf /tmp/pakui_temp.zip /tmp/pakui_temp; \
		fi; \
		echo "Saving diffs of modified BitPal files..."; \
		find BitPal -type f | while IFS= read -r file; do \
			relative_path=$${file#BitPal/}; \
			orig_path="/tmp/bitpal_original/$$relative_path"; \
			patch_path="patches/$$relative_path.patch"; \
			if ! diff -q "$$file" "$$orig_path" > /dev/null 2>&1; then \
				echo "Creating patch for $$relative_path"; \
				mkdir -p "$$(dirname "$$patch_path")"; \
				diff -u --label "$$orig_path" --label "$$file" "$$orig_path" "$$file" > "$$patch_path" || true; \
			fi; \
		done; \
		echo "Diffs saved to patches/ directory"; \
	else \
		echo "No BitPal directory found. Run 'make build' first."; \
		exit 1; \
	fi

apply-patches: build
	@echo "Applying saved diffs to BitPal files..."
	@if [ ! -d BitPal ]; then \
		echo "No BitPal directory found. Run 'make build' first."; \
		exit 1; \
	fi
	@find patches  -type f -name "*.patch" | while IFS= read -r patch; do \
		rel=$${patch#patches/}; \
		file_rel=$${rel%.patch}; \
		target="BitPal/$$file_rel"; \
		if [ -f "$$patch" ]; then \
			echo "Checking $$patch"; \
			if [ ! -f "$$target" ]; then \
				echo "Target file $$target does not exist."; \
			else \
				if patch --dry-run -s "$$target" < "$$patch" > /dev/null 2>&1; then \
					echo "Applying $$patch"; \
					patch --fuzz=0 "$$target" < "$$patch" || echo "Failed to apply $$patch"; \
				else \
					echo "Patch $$patch already applied or cannot be applied to $$target"; \
				fi; \
			fi; \
		fi; \
	done

release: apply-patches
	mkdir -p dist
	git archive --format=zip --output "dist/$(PAK_NAME).pak.zip" HEAD
	while IFS= read -r file; do zip -r "dist/$(PAK_NAME).pak.zip" "$$file"; done < .gitarchiveinclude
	ls -lah dist

push: release
	rm -rf "dist/$(PAK_NAME).pak"
	cd dist && unzip "$(PAK_NAME).pak.zip" -d "$(PAK_NAME).pak"
	@if [ -z "$(IP)" ]; then \
		echo "Error: IP parameter required. Usage: make push IP=<device_ip>"; \
		exit 1; \
	fi
	lftp -u minui,minui -e "mkdir -f $(PAK_FOLDER)/$(PUSH_PLATFORM)/$(PAK_NAME).pak; mirror -R dist/$(PAK_NAME).pak/ $(PAK_FOLDER)/$(PUSH_PLATFORM)/$(PAK_NAME).pak/; quit" $(IP)
	rm -rf "dist/$(PAK_NAME).pak"
