# own-ai deployments

This repository deploys the image built by
[own-ai](https://github.com/SAINIKHIL2902/own-ai). The application source,
tests, and Dockerfile live there.

## Promote or roll back a release

1. Open a successful **Publish application image** run in the application repository.
2. Copy the full image reference from the run summary into `release.env`.
3. Review and merge the change here, then deploy from that revision.

Docker Compose and Kubernetes both take the application image from
`release.env`. To roll back, restore the previous value and redeploy with the
same profile. Each application workflow run publishes a new tag. The initial
tag, `v1.0.2`, has an amd64 image. New builds publish amd64 and arm64.

## Docker Compose

Copy `.env.example` to `.env` if you are starting fresh. Put any optional
Gemini or other application credentials in your local `.env`.

```bash
./scripts/deploy.sh compose config --images
./scripts/deploy.sh compose pull app
./scripts/deploy.sh compose up -d
```

When moving an existing installation, reuse its Compose project name and
application data directory. Set `COMPOSE_PROJECT_NAME` to the original project
name and `OWN_AI_DATA_DIR` to the absolute path to its data directory in the new
checkout's `.env`. Stop the original stack without deleting volumes before
starting it from this checkout. The default data directory is `./data`.

## Kubernetes

Choose the existing deployment profile for your cluster. The helper defaults to
`all-in-one`. Supported profiles also include `deployment` and
`cloud-deployment`. For optional application credentials, manage the
`own-ai-secrets` Secret separately in the `own-ai` namespace.

```bash
./scripts/deploy.sh render cloud-deployment
./scripts/deploy.sh kubernetes cloud-deployment
```

The deploy command uses the current kubectl context, applies the rendered
manifest, waits for Ollama, pulls the baseline model, and waits for the
application rollout.
