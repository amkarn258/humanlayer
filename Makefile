.PHONY: check-py
check-py: ## Run code quality tools.
	: 🚀 installing uv deps
	uv sync
	: 🚀 Linting code: Running pre-commit
	uv run pre-commit run -a
	@$(MAKE) typecheck
	: 🚀 Checking for obsolete dependencies: Running deptry
	uv run deptry .

.PHONY: check-ts
check-ts:
	npm -C humanlayer-ts run check

.PHONY: check
check: check-py check-ts

typecheck: ## just the typechecks
	: 🚀 Static type checking: Running mypy
	uv run mypy

.PHONY: test-py
test-py: ## Test the code with pytest
	uv run pytest ./humanlayer --cov --cov-config=pyproject.toml --cov-report=xml --junitxml=junit.xml

.PHONY: test-ts
test-ts: ## Test the code with jest
	npm -C humanlayer-ts run test

.PHONY: test
test: test-py test-ts

.PHONY: build
build: clean-build ## Build wheel file using uv
	: 🚀 Creating wheel file
	uv build

.PHONY: build-ts
build-ts:
	npm -C humanlayer-ts run build

.PHONY: clean-build
clean-build: ## clean build artifacts
	@rm -rf dist

.PHONY: publish-py
publish-py: ## publish a release to pypi. with UV_PUBLISH_TOKEN
	: 🚀 Publishing.
	uv publish

.PHONY: publish
publish: publish-py

.PHONY: publish-ts
publish-ts: build-ts
	npm -C humanlayer-ts publish

.PHONY: build-and-publish
build-and-publish: build publish ## Build and publish.

.PHONY: help
help:
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

.PHONY: smoke-test-examples-py
smoke-test-examples-py:
	examples/langchain/venv/bin/pip install -r examples/langchain/requirements.txt
	: 🦾 human_as_tool_linkedin
	examples/langchain/venv/bin/python examples/langchain/04-human_as_tool_linkedin.py
	: 🦾 human_as_tool_linkedin
	examples/langchain/venv/bin/python examples/langchain/04-human_as_tool_linkedin_frustration.py
	examples/langchain/venv/bin/python examples/langchain/09-email-contact.py

.PHONY: smoke-test-examples-ts
smoke-test-examples-ts:
	npm -C examples/ts_openai_client install
	: 🦾 human-as-tool
	npm -C examples/ts_openai_client run human-as-tool
	: 🦾 human-email
	npm -C examples/ts_openai_client run human-email

	npm -C examples/ts_langchain install
	: 🦾 ts_langchain
	npm -C examples/ts_langchain run example

.PHONY: smoke-test-examples
smoke-test-examples: smoke-test-examples-py smoke-test-examples-ts

.PHONY: test-examples
test-examples:
	:
	: 🦾 controlflow
	:
	examples/controlflow/venv/bin/pip install -r examples/controlflow/requirements.txt
	examples/controlflow/venv/bin/python examples/controlflow/controlflow_math.py
	:
	: 🚣 crewai
	:
	examples/crewai/venv/bin/pip install -r examples/crewai/requirements.txt
	examples/crewai/venv/bin/python examples/crewai/crewai_math.py
	examples/crewai/venv/bin/python examples/crewai/crewai_onboarding_agent.py
	examples/crewai/venv/bin/python examples/crewai/crewai_onboarding_agent_human_as_tool.py
	:
	: 🚣 griptape
	:
	examples/griptape/venv/bin/pip install -r examples/griptape/requirements.txt
	examples/griptape/venv/bin/python examples/griptape/01-math_example.py
	:
	: 🦜⛓️ langchain
	:
	examples/langchain/venv/bin/pip install -r examples/langchain/requirements.txt
	examples/langchain/venv/bin/python examples/langchain/01-math_example.py
	examples/langchain/venv/bin/python examples/langchain/02-customer_email.py
	examples/langchain/venv/bin/python examples/langchain/04-human_as_tool_linkedin.py
	examples/langchain/venv/bin/python examples/langchain/04-human_as_tool_onboarding.py
	examples/langchain/venv/bin/python examples/langchain/04-human_as_tool_linkedin_frustration.py
	examples/langchain/venv/bin/python examples/langchain/05-approvals_and_humans_composite.py
	examples/langchain/venv/bin/python examples/langchain/08-email-channel.py
	examples/langchain/venv/bin/python examples/langchain/09-email-contact.py
	:
	: 🦜⛓️ langchain-anthropic
	:
	examples/langchain-anthropic/venv/bin/pip install -r examples/langchain-anthropic/requirements.txt
	examples/langchain-anthropic/venv/bin/python examples/langchain-anthropic/01-math_example.py
	:
	: 🧠 OpenAI
	:
	examples/openai_client/venv/bin/pip install -r examples/openai_client/requirements.txt
	examples/openai_client/venv/bin/python examples/openai_client/02-imperative_fetch.py
	examples/openai_client/venv/bin/python examples/openai_client/03-imperative_fetch_based.py
	:
	: 🦜⛓️ ts_langchain
	:
	npm run --prefix examples/ts_langchain example
	:
	: 🧠 ts_openai
	:
	npm run --prefix examples/ts_openai_client example
	npm run --prefix examples/ts_openai_client human-as-tool
	npm run --prefix examples/ts_openai_client human-email
	npm run --prefix examples/ts_openai_client agent-side

.PHONY: githooks
githooks:
	:
	: 🚀 Installing pre-push hook
	:
	echo 'make check test' > .git/hooks/pre-push
	chmod +x .git/hooks/pre-push

.PHONY: update-examples-versions
VERSION?=
update-examples-versions:
	@if [ -z "$(VERSION)" ]; then \
		echo "VERSION is not set"; \
		exit 1; \
	fi; \
	: 🚀 Updating examples versions to $(VERSION)
	find examples/*/requirements.txt -type f -exec sed -i '' 's/humanlayer==.*$$/humanlayer==$(VERSION)/g' {} +

.PHONY: update-examples-ts-versions
update-examples-ts-versions:
	find examples/*/package.json -type f -exec sed -i '' 's/"humanlayer": ".*"/"humanlayer": "$(VERSION)"/g' {} +

.PHONY: update-examples-tokens
HUMANLAYER_API_KEY?=
HUMANLAYER_API_BASE?=
update-examples-tokens:
	@if [ -z "$(HUMANLAYER_API_KEY)" ]; then \
		echo "HUMANLAYER_API_KEY must be set"; \
		exit 1; \
	fi; \
	: 🚀 Updating examples .env files with new tokens
	find examples/*/.env -type f -exec sh -c ' \
		echo "" >> "{}"; \
		echo "# added by Makefile at $(shell date)" >> "{}"; \
		echo "HUMANLAYER_API_KEY=$(HUMANLAYER_API_KEY)" >> "{}"; \
		echo "HUMANLAYER_API_BASE=$(HUMANLAYER_API_BASE)" >> "{}"; \
	' \;
