#!/usr/bin/env bash
set -euo pipefail

# Symlinks skill folders from this repo into ~/.claude/skills/.
# Discovers buckets dynamically — any directory under `skills/` that contains
# at least one SKILL.md becomes a selectable bucket. New buckets (e.g.
# `managerial/`) appear automatically once they have content.
#
# Defaults (when no flags): prompts Y/n per bucket.
#   engineering, productivity, misc → default Y
#   personal, deprecated, anything else → default N

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/.claude/skills"
DEFAULT_YES_RE='^(engineering|productivity|misc)$'

usage() {
  cat <<EOF
Usage: $0 [options]

Symlinks skill folders from this repo into ~/.claude/skills/.

Options:
  --all              Install every discovered bucket without prompting
  --buckets <list>   Comma-separated buckets to install (e.g. engineering,personal)
  -y, --yes          Accept defaults (engineering, productivity, misc)
  --clean            Remove existing symlinks pointing into this repo before installing
  -h, --help         Show this help

With no flags: prompts Y/n per bucket. Default Y for engineering, productivity,
misc; default N for everything else.
EOF
}

# --- parse args ---
MODE=interactive
SELECTION=""
CLEAN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all) MODE=all; shift;;
    --buckets) MODE=explicit; SELECTION="${2:-}"; shift 2;;
    -y|--yes) MODE=defaults; shift;;
    --clean) CLEAN=true; shift;;
    -h|--help) usage; exit 0;;
    *) echo "error: unknown option '$1'" >&2; usage; exit 2;;
  esac
done

# --- safety check ---
# If ~/.claude/skills is a symlink that resolves into this repo, we'd end up
# writing the per-skill symlinks back into the repo's own skills/ tree.
if [ -L "$DEST" ]; then
  resolved="$(readlink -f "$DEST" 2>/dev/null || readlink "$DEST")"
  case "$resolved" in
    "$REPO"|"$REPO"/*)
      echo "error: $DEST is a symlink into this repo ($resolved)." >&2
      echo "Remove it (rm \"$DEST\") and re-run; the script will recreate it as a real dir." >&2
      exit 1
      ;;
  esac
fi

mkdir -p "$DEST"

# --- discover buckets ---
BUCKETS=()
while IFS= read -r -d '' bucket_dir; do
  if find "$bucket_dir" -name SKILL.md -not -path '*/node_modules/*' -print -quit 2>/dev/null | grep -q .; then
    BUCKETS+=("$(basename "$bucket_dir")")
  fi
done < <(find "$REPO/skills" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

if [ ${#BUCKETS[@]} -eq 0 ]; then
  echo "error: no buckets found under $REPO/skills" >&2
  exit 1
fi

# --- decide selection ---
SELECTED=()
case "$MODE" in
  all)
    SELECTED=("${BUCKETS[@]}")
    ;;
  defaults)
    for b in "${BUCKETS[@]}"; do
      [[ "$b" =~ $DEFAULT_YES_RE ]] && SELECTED+=("$b")
    done
    ;;
  explicit)
    if [ -z "$SELECTION" ]; then
      echo "error: --buckets requires a comma-separated list" >&2
      exit 2
    fi
    IFS=',' read -ra requested <<< "$SELECTION"
    for r in "${requested[@]}"; do
      r_trim="$(echo -n "$r" | tr -d '[:space:]')"
      [ -z "$r_trim" ] && continue
      matched=false
      for b in "${BUCKETS[@]}"; do
        if [ "$b" = "$r_trim" ]; then SELECTED+=("$b"); matched=true; break; fi
      done
      $matched || echo "warning: bucket '$r_trim' not found — skipping" >&2
    done
    ;;
  interactive)
    if [ ! -t 0 ] && [ ! -e /dev/tty ]; then
      echo "error: interactive mode needs a TTY. Use --all, --yes, or --buckets." >&2
      exit 2
    fi
    echo "Available buckets in $REPO/skills:"
    for b in "${BUCKETS[@]}"; do
      count="$(find "$REPO/skills/$b" -name SKILL.md -not -path '*/node_modules/*' | wc -l | tr -d ' ')"
      printf "  %-15s (%s skills)\n" "$b" "$count"
    done
    echo
    # Read prompts from /dev/tty so piping data doesn't break the questions
    if [ -e /dev/tty ]; then exec 3</dev/tty; else exec 3<&0; fi
    for b in "${BUCKETS[@]}"; do
      if [[ "$b" =~ $DEFAULT_YES_RE ]]; then
        prompt="Install $b? [Y/n] "; default_yes=true
      else
        prompt="Install $b? [y/N] "; default_yes=false
      fi
      printf "%s" "$prompt"
      IFS= read -r answer <&3 || answer=""
      if [ -z "$answer" ]; then
        $default_yes && SELECTED+=("$b")
      elif [[ "$answer" =~ ^[Yy] ]]; then
        SELECTED+=("$b")
      fi
    done
    exec 3<&-
    ;;
esac

if [ ${#SELECTED[@]} -eq 0 ]; then
  echo "No buckets selected — nothing to do."
  exit 0
fi

# --- clean stale symlinks pointing into this repo (if --clean) ---
if $CLEAN; then
  echo
  echo "Cleaning stale symlinks pointing into $REPO ..."
  while IFS= read -r -d '' link; do
    target="$(readlink "$link" 2>/dev/null || true)"
    case "$target" in
      "$REPO"/*)
        echo "  removed $(basename "$link")"
        rm "$link"
        ;;
    esac
  done < <(find "$DEST" -maxdepth 1 -type l -print0 2>/dev/null)
fi

# --- link selected ---
echo
echo "Installing: ${SELECTED[*]}"
echo "Destination: $DEST"
echo
for bucket in "${SELECTED[@]}"; do
  bucket_dir="$REPO/skills/$bucket"
  while IFS= read -r -d '' skill_md; do
    src="$(dirname "$skill_md")"
    name="$(basename "$src")"
    target="$DEST/$name"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
      rm -rf "$target"
    fi

    ln -sfn "$src" "$target"
    printf "  linked %-35s (%s)\n" "$name" "$bucket"
  done < <(find "$bucket_dir" -name SKILL.md -not -path '*/node_modules/*' -print0)
done
