#!/usr/bin/env bash
set -euo pipefail

# Launch Claude Code inside the hardened "clank" nono sandbox.
#
# Which profile to launch under (default: the secure base). Examples:
#   ./clank.sh                          # secure base, no kube/docker
#   PROFILE=clank-kube ./clank.sh       # + ~/.kube
#   PROFILE=clank-docker ./clank.sh     # + OrbStack docker socket only
#   PROFILE=clank-orbstack ./clank.sh   # + full OrbStack (orb/orbctl)
CLANK_PROFILE="${CLANK_PROFILE:-clank}"
CLANK_CMD="${CLANK_CMD:-claude}"

# Ephemeral, throwaway package-manager caches under $TMPDIR, isolated from the
# real caches so a compromised tool can't poison state our host later trusts
# and executes from. The profile grants r+w to $TMPDIR/clank-cache ONLY.
CLANK_CACHE="${TMPDIR:-/tmp}/clank-cache"
mkdir -p "$CLANK_CACHE"/{npm,uv,go,go-build,xdg,pre-commit,tfenv,terraform,aws}

export NPM_CONFIG_CACHE="$CLANK_CACHE/npm"
export UV_CACHE_DIR="$CLANK_CACHE/uv"
export GOPATH="$CLANK_CACHE/go"          # GOMODCACHE defaults to $GOPATH/pkg/mod
export GOCACHE="$CLANK_CACHE/go-build"
export XDG_CACHE_HOME="$CLANK_CACHE/xdg" # pip and many others honor this
export PRE_COMMIT_HOME="$CLANK_CACHE/pre-commit"

# tfenv and terraform default to reading/writing paths outside the sandboxed
# root (~/.config/tfenv, ~/.terraformrc, ~/.aws/*), so each needs a
# sandbox-writable redirect or the tool aborts on a permission error before
# it gets anywhere near actually calling AWS.
export TFENV_CONFIG_DIR="$CLANK_CACHE/tfenv"
export TF_CLI_CONFIG_FILE="$CLANK_CACHE/terraform/terraformrc"
export AWS_CONFIG_FILE="$CLANK_CACHE/aws/config"
export AWS_SHARED_CREDENTIALS_FILE="$CLANK_CACHE/aws/credentials"
touch "$TF_CLI_CONFIG_FILE" "$AWS_CONFIG_FILE" "$AWS_SHARED_CREDENTIALS_FILE"
unset TF_PLUGIN_CACHE_DIR

# --allow-cwd: the profile's workdir.access sets the CWD access *level*
# (readwrite); this flag grants it without an interactive prompt at startup.
exec nono run --profile "$CLANK_PROFILE" --allow-cwd -- "$CLANK_CMD" "$@"
