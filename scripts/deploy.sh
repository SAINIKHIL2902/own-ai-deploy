#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Read the version-controlled release as data so it cannot execute shell code.
entry=$(<release.env)
image=${entry#OWN_AI_IMAGE=}
image_pattern='^[a-z0-9][a-z0-9.-]*(:[0-9]+)?/([a-z0-9][a-z0-9._-]*/)*[a-z0-9][a-z0-9._-]*:[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$'
if [[ "$entry" == "$image" || ! "$image" =~ $image_pattern || "${image##*:}" == latest ]]; then
    echo "release.env must contain one OWN_AI_IMAGE=registry/path:version entry. Choose a versioned tag." >&2
    exit 1
fi
export OWN_AI_IMAGE="$image"

render_manifest() {
    local profile=$1
    case "$profile" in
        all-in-one|cloud-deployment|deployment)
            sed "s|__OWN_AI_IMAGE__|$OWN_AI_IMAGE|g" "k8s/$profile.yaml.in"
            ;;
        *)
            echo "Choose a Kubernetes profile: all-in-one, cloud-deployment, or deployment." >&2
            return 2
            ;;
    esac
}

case "${1:-}" in
    compose)
        shift
        exec docker compose -f docker-compose.deploy.yml "$@"
        ;;
    render)
        render_manifest "${2:-all-in-one}"
        ;;
    kubernetes)
        render_manifest "${2:-all-in-one}" | kubectl apply -f -
        kubectl rollout status deployment/ollama -n own-ai --timeout=120s
        kubectl exec deployment/ollama -n own-ai -- ollama pull llama3.2:1b
        kubectl rollout status deployment/own-ai-app -n own-ai --timeout=180s
        ;;
    *)
        echo "Usage: $0 {compose [args...]|render [profile]|kubernetes [profile]}" >&2
        exit 2
        ;;
esac
