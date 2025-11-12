PG_TAG ?= $(shell \
      git rev-parse --abbrev-ref HEAD 2>/dev/null || \
      echo local)

.PHONY: check-registry
check-registry:
	@if [ -z "$(PG_REGISTRY)" ]; then \
		echo "ERROR: PG_REGISTRY is not set."; \
		echo ""; \
		echo "You must specify the Container Registry prefix before"; \
		echo "running the build.  Example:"; \
		echo ""; \
		echo "    make cpu PG_REGISTRY=docker.io/predictionguard"; \
		echo ""; \
		echo "or export it in your shell:"; \
		echo ""; \
		echo "    export PG_REGISTRY=docker.io/predictionguard"; \
		echo "    make cpu"; \
		exit 1; \
	fi

.PHONY: pre-run-checks
pre-run-checks: check-registry

.PHONY: cpu
cpu: pre-run-checks
	docker buildx build \
		--platform=linux/amd64 \
		--target vllm-openai \
		--push \
		-t $(PG_REGISTRY)/vllm-cpu:$(PG_TAG) \
		-f docker/Dockerfile.cpu \
		.

.PHONY: cuda
cuda: pre-run-checks
	docker buildx build \
		--platform=linux/amd64 \
		--target vllm-openai \
		--push \
		--build-arg "RUN_WHEEL_CHECK=false" \
		--build-arg "SCCACHE_S3_NO_CREDENTIALS=1" \
		--build-arg "max_jobs=16" \
		--build-arg "nvcc_threads=16" \
		-t $(PG_REGISTRY)/vllm-cuda:$(PG_TAG) \
		-f docker/Dockerfile \
		.
