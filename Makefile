ANSI_BOLD := $(if $NO_COLOR,$(shell tput bold 2>/dev/null),)
ANSI_RESET := $(if $NO_COLOR,$(shell tput sgr0 2>/dev/null),)

# Switch this to podman if you are using that in place of docker
CONTAINERTOOL := docker

MODULE_NAME := $(lastword $(subst /, ,$(shell go list -m)))
VERSION := $(if $(shell git status --porcelain 2>/dev/null),latest,$(shell git rev-parse HEAD))


# This isn't my original code, taken (and slightly modified) from other public actions
.PHONY: build
build:  ## Build the container image
	@echo "$(ANSI_BOLD)⚡️ Building container image ...$(ANSI_RESET)"
	@$(CONTAINERTOOL) build --rm -t $(MODULE_NAME):$(VERSION) -t $(MODULE_NAME):latest -f Dockerfile .
	@echo "$(ANSI_BOLD)✅ Container image built$(ANSI_RESET)"

.PHONY: test
test: ## Runs unit tests
	@echo "$(ANSI_BOLD)⚡️ Running unit tests ...$(ANSI_RESET)"
	@go test ./...
	@echo "$(ANSI_BOLD)✅ Unit tests passed$(ANSI_RESET)"

.PHONY: verify
verify: format test ## Verifies that the committed code is formatted, all files are in sync and the unit tests pass
	@if [ "`git status --porcelain 2>/dev/null`x" = "x" ] ; then \
	  echo "$(ANSI_BOLD)✅ Git workspace is clean$(ANSI_RESET)" ; \
	else \
	  echo "$(ANSI_BOLD)❌ Git workspace is dirty$(ANSI_RESET)" ; \
	  exit 1 ; \
	fi

.cloudbees/workflows/workflow.yml: Dockerfile ## Ensures that the workflow uses the same version of go as the Dockerfile
	@echo "$(ANSI_BOLD)⚡️ Updating $@ ...$(ANSI_RESET)"
	@IMAGE=$$(sed -ne 's/FROM[ \t]*golang:\([^ \t]*\)-alpine[0-9.]*[ \t].*/\1/p' Dockerfile) ; \
	sed -e 's|\(uses:[ \t]*docker://golang:\)[^ \t]*|\1'"$$IMAGE"'|;' < $@ > $@.bak ; \
	mv -f $@.bak $@

.PHONY: format
format: ## Applies the project code style
	@echo "$(ANSI_BOLD)⚡️ Applying project code style ...$(ANSI_RESET)"
	@gofmt -w .
	@echo "$(ANSI_BOLD)✅ Project code style applied$(ANSI_RESET)"

##@ Release

.PHONY: -check-main-matches-remote
-check-main-matches-remote:
	@echo "$(ANSI_BOLD)⚡️ Checking local 'main' branch against remote ...$(ANSI_RESET)"
	@git fetch origin --force --tags main 2>/dev/null && \
	if [ "$$(git rev-parse main)" = "$$(git rev-parse origin/main)" ] ; then \
	  echo "$(ANSI_BOLD)✅ Remote 'main' branch matches local 'main' branch$(ANSI_RESET)" ; \
	else \
	  echo "$(ANSI_BOLD)❌ Remote 'main' branch does not match local 'main' branch$(ANSI_RESET)" ; \
	  exit 1 ; \
	fi

.PHONY: -check-main-already-tagged
-check-main-already-tagged: -check-main-matches-remote
	@if [ "`git status --porcelain 2>/dev/null`x" = "x" ] ; then \
	  echo "$(ANSI_BOLD)✅ Git workspace is clean$(ANSI_RESET)" ; \
	else \
	  echo "$(ANSI_BOLD)❌ Must be in a clean Git workspace to run this target$(ANSI_RESET)" ; \
	  exit 1 ; \
	fi
	@if [ "$$(git rev-parse main)" = "$$(git rev-parse HEAD)" ] ; then \
	  echo "$(ANSI_BOLD)✅ On 'main' branch$(ANSI_RESET)" ; \
	else \
	  echo "$(ANSI_BOLD)❌ Must be on 'main' branch to run this target $(ANSI_RESET)" ; \
	  exit 1 ; \
	fi
	@LAST_VERSION="$$(git describe --tags --match 'v*.*.*' --exact-match main 2>/dev/null | sed -e 's:^tags/::')" ; \
	if [ "$$(git rev-parse main)" = "$$(git rev-parse "$${LAST_VERSION}^{commit}"  2>/dev/null)" ] ; then \
	  echo "$(ANSI_BOLD)❌ Tags for 'main' were already created as version $$LAST_VERSION$(ANSI_RESET)" ; \
	  exit 1 ; \
	else \
	  echo "$(ANSI_BOLD)✅ Lastest 'main' branch has not been tagged yet$(ANSI_RESET)" ; \
	fi

.PHONY: preview-patch-release
preview-patch-release: -check-main-already-tagged ## Displays the next a patch release from the main branch
	@echo "$(ANSI_BOLD)ℹ️  Next patch release version $$(go run .cloudbees/release/next-version.go)$(ANSI_RESET)"

.PHONY: preview-minor-release
preview-minor-release: -check-main-already-tagged ## Displays the next a minor release from the main branch
	@echo "$(ANSI_BOLD)ℹ️  Next patch release version $$(go run .cloudbees/release/next-version.go)$(ANSI_RESET)"

.PHONY: preview-major-release
preview-major-release: -check-main-already-tagged ## Displays the next a major release from the main branch
	@echo "$(ANSI_BOLD)ℹ️  Next patch release version $$(go run .cloudbees/release/next-version.go)$(ANSI_RESET)"

.PHONY: prepare-patch-release
prepare-patch-release: -check-main-already-tagged ## Creates a tag for a patch release from the main branch
	@NEXT_VERSION="$$(go run .cloudbees/release/next-version.go)" ; \
	echo "$(ANSI_BOLD)⚡️ Tagging version $$NEXT_VERSION ...$(ANSI_RESET)" ; \
	git tag -f -a -m "chore: $$NEXT_VERSION release" $$NEXT_VERSION main ; \
	echo "$(ANSI_BOLD)✅ Version $$NEXT_VERSION tagged from branch 'main'$(ANSI_RESET)"

.PHONY: prepare-minor-release
prepare-minor-release: -check-main-already-tagged ## Creates a tag for a minor release from the main branch
	@NEXT_VERSION="$$(go run .cloudbees/release/next-version.go --minor)" ; \
	echo "$(ANSI_BOLD)⚡️ Tagging version $$NEXT_VERSION ...$(ANSI_RESET)" ; \
	git tag -f -s -m "chore: $$NEXT_VERSION release" $$NEXT_VERSION main ; \
	echo "$(ANSI_BOLD)✅ Version $$NEXT_VERSION tagged from branch 'main'$(ANSI_RESET)"

.PHONY: prepare-major-release
prepare-major-release: -check-main-already-tagged ## Creates a tag for a major release from the main branch
	@NEXT_VERSION="$$(go run .cloudbees/release/next-version.go --major)" ; \
	echo "$(ANSI_BOLD)⚡️ Tagging version $$NEXT_VERSION ...$(ANSI_RESET)" ; \
	git tag -f -s -m "chore: $$NEXT_VERSION release" $$NEXT_VERSION main ; \
	echo "$(ANSI_BOLD)✅ Version $$NEXT_VERSION tagged from branch 'main'$(ANSI_RESET)"

.PHONY: publish-release
publish-release: ## Pushes the latest release tag for the current commit's release tag
	@CUR_VERSION="$$(git describe --tags --match 'v*.*.*' --exact-match 2>/dev/null | sed -e 's:^tags/::')" ; \
	if [ -z "$${CUR_VERSION}" ] ; \
	then \
		echo "$(ANSI_BOLD)❌ Current commit does not have a release tag$(ANSI_RESET)" ; \
		exit 1 ; \
	fi ; \
	echo "$(ANSI_BOLD)⚡️ Publishing current commit's release tag $$CUR_VERSION ...$(ANSI_RESET)" ; \
	git push --force origin $$CUR_VERSION ; \
	echo "$(ANSI_BOLD)✅ Release tag $$CUR_VERSION published$(ANSI_RESET)"

##@ Miscellaneous

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

