.PHONY: init-cpu \
	init-gpu \
	docker-build \
	docker-up \
	docker-down \
	init-docker-cpu \
	init-docker-gpu \
	docker-build-cpu-no-cache \
	docker-build-gpu-no-cache \
	docker-shell \
	init-working-dir \
	setup-vscode \
	setup-vscode-insiders \
	setup-container \
	reset-notebook \
	start-jupyter \
	fix \
	ruff-fix \
	lint \
	ruff-check \
	ruff-format \
	mypy-check \
	stop-jupyter \
	to-notion \
	test

init-runtime-cpu: 
	@echo "RUNTIME=cpu" >> ./.env_project

init-runtime-gpu: 
	@echo "RUNTIME=gpu" >> ./.env_project

init-working-dir:
	@echo "PARENT_DIR=$(shell dirname $(shell pwd))" >> ./.env_project

init-base:
	@rm -f .env_project && touch .env_project
	@echo "PROJECT_DIR=$(shell basename $(shell pwd))" >> ./.env_project
	@echo "PROJECT=$(shell basename $(shell pwd) | tr '[:upper:]' '[:lower:]')" >> ./.env_project
	@echo "USER_UID=$(shell id -u $(USER))" >> ./.env_project
	@echo "SANITIZED_USER=$(subst .,-,$(USER))" >> ./.env_project
	$(MAKE) init-working-dir

init-cpu: 
	$(MAKE) init-base
	$(MAKE) init-runtime-cpu

init-gpu: 
	$(MAKE) init-base
	$(MAKE) init-runtime-gpu

docker-up-cpu:
	@. ./.env_project && docker compose --env-file .env_project -f context/cpu/docker-compose.yml -p $${PROJECT}-$${SANITIZED_USER}-$${USER_UID} up -d

docker-up-gpu:
	@. ./.env_project && docker compose --env-file .env_project -f context/gpu/docker-compose.yml -p $${PROJECT}-$${SANITIZED_USER}-$${USER_UID} up -d

docker-down:
	@. ./.env_project && docker compose -p $${PROJECT}-$${SANITIZED_USER}-$${USER_UID} down

docker-down-rmi:
	@. ./.env_project && docker compose -p $${PROJECT}-$${SANITIZED_USER}-$${USER_UID} down --rmi all

docker-stop:
	@. ./.env_project && docker compose -p $${PROJECT}-$${SANITIZED_USER}-$${USER_UID} stop

docker-build-cpu:
	$(MAKE) init-cpu
	@. ./.env_project && docker compose --env-file .env_project -f context/cpu/docker-compose.yml -p $${PROJECT}-$${SANITIZED_USER}-$${USER_UID} build

docker-build-gpu:
	$(MAKE) init-gpu
	@. ./.env_project && docker compose --env-file .env_project -f context/gpu/docker-compose.yml -p $${PROJECT}-$${SANITIZED_USER}-$${USER_UID} build

docker-build-cpu-no-cache:
	$(MAKE) init-cpu
	@. ./.env_project && docker compose --env-file .env_project -f context/cpu/docker-compose.yml -p $${PROJECT}-$${SANITIZED_USER}-$${USER_UID} build --no-cache

docker-build-gpu-no-cache:
	$(MAKE) init-gpu
	@. ./.env_project && docker compose --env-file .env_project -f context/gpu/docker-compose.yml -p $${PROJECT}-$${SANITIZED_USER}-$${USER_UID} build --no-cache

init-docker-cpu:
	$(MAKE) init-cpu
	$(MAKE) docker-up-cpu

init-docker-gpu:
	$(MAKE) init-gpu
	$(MAKE) docker-up-gpu

docker-shell:
	@. ./.env_project; \
	CONTAINER_NAME=$${PROJECT}_$${SANITIZED_USER}_$${USER_UID}; \
	if ! docker ps --filter "name=^$${CONTAINER_NAME}$$" --format "{{.Names}}" | grep -q $${CONTAINER_NAME}; then \
		echo "Error: Docker container '$${CONTAINER_NAME}' is not running. Please run 'make init-docker-cpu' or 'make init-docker-gpu' to start it." >&2; \
		exit 1; \
	else \
		docker exec -it $${CONTAINER_NAME} /bin/bash; \
	fi

docker-rmi:
	@. ./.env_project; \
	IMAGE_NAME=$${PROJECT}:$${SANITIZED_USER}_$${USER_UID}; \
	echo "🗑️ Removing Docker image '$${IMAGE_NAME}'..."; \
	if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$${IMAGE_NAME}$$"; then \
		docker rmi $${IMAGE_NAME} \
		&& echo "✅ Docker image '$${IMAGE_NAME}' has been removed." \
		|| echo "❌ Failed to remove Docker image '$${IMAGE_NAME}'. Did you stop and delete the container by 'make docker-down'?"; \
	else \
		echo "❌ Docker image '$${IMAGE_NAME}' does not exist."; \
	fi

reset-notebook:
	$(eval args := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval arg1 := $(word 1, $(args)))
	@jupyter nbconvert --clear-output --inplace `find $(arg1) -name *ipynb`

setup-vscode:
	@code --install-extension ms-python.python
	@code --install-extension ms-python.mypy-type-checker
	@code --install-extension charliermarsh.ruff
	@code --install-extension Gxl.git-graph-3
	@code --install-extension GitHub.copilot
	@code --install-extension ms-toolsai.jupyter

setup-vscode-insiders:
	@code-insiders --install-extension ms-python.python
	@code-insiders --install-extension ms-python.mypy-type-checker
	@code-insiders --install-extension charliermarsh.ruff
	@code-insiders --install-extension Gxl.git-graph-3
	@code-insiders --install-extension GitHub.copilot
	@code-insiders --install-extension ms-toolsai.jupyter

start-jupyter:
	$(eval args := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval arg1 := $(if $(word 1, $(args)), $(word 1, $(args)),.))
	@. ./.env_project && docker exec $${PROJECT}_$${SANITIZED_USER}_$${USER_UID} /bin/bash -c \
		"uv sync --dev --all-groups \
		&& uv run ipython kernel install --user --name=$${PROJECT} \
		&& uv run jupyter lab --no-browser --port 8888 --ip=0.0.0.0 --allow-root --NotebookApp.token='' --notebook-dir='$(arg1)'"

stop-jupyter:
	@. ./.env_project && docker exec $${PROJECT}_$${SANITIZED_USER}_$${USER_UID} /bin/bash -c \
		"pkill -f jupyter"

lint:
	$(eval args := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval arg1 := $(word 1, $(args)))
	$(MAKE) ruff-check $(arg1); \
	$(MAKE) ruff-format $(arg1); \
	$(MAKE) mypy-check $(arg1)

ruff-check:
	$(eval args := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval arg1 := $(word 1, $(args)))
	uv run ruff check $(arg1) --config ./ruff.toml

ruff-format:
	$(eval args := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval arg1 := $(word 1, $(args)))
	uv run ruff format --check $(arg1) --config ./ruff.toml

mypy-check:
	$(eval args := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval arg1 := $(word 1, $(args)))
	uv run mypy $(arg1) --config-file ./mypy.ini

fix:
	$(eval args := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval arg1 := $(word 1, $(args)))
	$(MAKE) ruff-fix $(arg1)

ruff-fix:
	$(eval args := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval arg1 := $(word 1, $(args)))
	uv run ruff check --fix $(arg1) --config ./ruff.toml; \
	uv run ruff format $(arg1) --config ./ruff.toml

test:
	uv run pytest $(filter-out $@,$(MAKECMDGOALS)) \

to-notion:
	$(eval args := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval arg1 := $(word 1, $(args)))
	$(eval arg2 := $(word 2, $(args)))
	@echo "notebook: $(arg1)"
	@echo "notion page title: $(arg2)"
	@uv run python ./libs/abeja-toolkit/notebook_exporter/export.py notion -nb $(arg1) --title $(arg2)

SYNC_TEMPLATE_FLAGS := \
	$(if $(VERSION),--version $(VERSION)) \
	$(if $(DEBUG),--debug) \
	$(if $(NO_BRANCH), --no-branch)

sync-template:
	@echo "Syncing the DSG project template..."
	@scripts/sync_dsg-project-template.sh $(SYNC_TEMPLATE_FLAGS)

%:
	@:
