#!/usr/bin/env bash
# =============================================================================
# link-skills.sh — backward-compatible wrapper
# =============================================================================
# Delegates to install.sh with --harness claude so existing workflows (and the
# README quickstart) keep working unchanged.
#
# For multi-harness installs use install.sh directly:
#   ./scripts/install.sh --harness claude,pi,codex
# =============================================================================
exec "$(dirname "$0")/install.sh" --harness claude "$@"
