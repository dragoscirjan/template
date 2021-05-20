include Makefile.include

## Add your make instructions here

configure: ## Configure and Init the code dependencies
	@echo "Configure and Init the code dependencies"

docs: ## Generate documentation for the Project
	@echo "Generate documentation for the Project"

test: ## Run Tests
	@echo "Run Tests"

build: ## Build Application
	@echo 'Build instructions'

install: ## Install Application
	@echo 'Install Instructions'

uninstall: ## Uninstall Application
	@echo 'Uninstall Instructions'

RELEASE_OPTIONS = -Patch -Dry
release: release-$(SHELL_IS) ## Publish code & mark for release

release-bash:
	bash ./.scripts/release-tag.sh $(RELEASE_OPTIONS)

release-powershell:
	$(POWERSHELL) -File ./.scripts/release-tag.ps1 $(RELEASE_OPTIONS)

