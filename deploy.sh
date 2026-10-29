#!/usr/bin/env bash

# A subshell keeps source deploy.sh from changing the caller's shell options.
(
  set -e

  if [ -n "${ZSH_VERSION:-}" ]; then
    script_path=${(%):-%x}
  else
    script_path=${BASH_SOURCE[0]}
  fi
  cd -- "$(dirname -- "$script_path")"

  deploy_user=${DEPLOY_GITHUB_USER:-mxprnc}
  deploy_repo=mxprnc/docs-spring-webflux

  if ! command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI (gh) is required for deployment." >&2
    exit 1
  fi

  echo ">>> select GitHub account: $deploy_user"
  if ! gh auth switch --hostname github.com --user "$deploy_user"; then
    echo "Log in as $deploy_user, then run this script again:" >&2
    echo "  gh auth login --hostname github.com --git-protocol https --web" >&2
    exit 1
  fi

  active_user=$(gh api --hostname github.com user --jq .login)
  if [ "$active_user" != "$deploy_user" ]; then
    echo "Expected $deploy_user, but GitHub authenticated as $active_user." >&2
    echo "Check GH_TOKEN/GITHUB_TOKEN overrides in your shell." >&2
    exit 1
  fi

  can_push=$(gh api --hostname github.com "repos/$deploy_repo" --jq '.permissions.push')
  if [ "$can_push" != "true" ]; then
    echo "$deploy_user does not have write permission to $deploy_repo." >&2
    exit 1
  fi

  echo ">>> clean previous build"
  rm -rf out .next

  echo ">>> build"
  npm run build

  echo ">>> deploy"
  # Build explicitly instead of depending on package-manager lifecycle hooks.
  npm --ignore-scripts run deploy

  echo ">>> clean successful build"
  rm -rf out .next
)
