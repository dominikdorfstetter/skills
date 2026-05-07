#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# dominiks-skills — harness-agnostic installer
# =============================================================================
# Symlinks skill folders from this repo into one or more coding-harness skill
# directories.  Supports Claude Code, Pi, Codex, Gemini CLI, Cursor, and the
# shared `~/.agents/skills/` location (agentskills.io convention).
#
# Usage:
#   ./install.sh                          # interactive: buckets + harnesses
#   ./install.sh --harness claude,pi       # pick harnesses, prompt for buckets
#   ./install.sh --harness all --all       # everything, no prompts
#   ./install.sh --harness agents --yes    # shared location, default buckets
#   ./install.sh --dry-run --all --harness all
#   ./install.sh --help
# =============================================================================

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEFAULT_YES_RE='^(engineering|productivity|misc)$'

# --- harness registry --------------------------------------------------------
# Parallel arrays: HARNESS_IDS, HARNESS_LABELS, HARNESS_DESTS (same order).
HARNESS_IDS=(    claude   pi      codex   gemini   cursor   agents )
HARNESS_LABELS=( "Claude Code"
                 "Pi"
                 "Codex (OpenAI)"
                 "Gemini CLI"
                 "Cursor"
                 "Shared (~/.agents/skills)" )

harness_index() {
  # Echo the array index for a harness id, or -1 if not found.
  local needle="$1" i
  for i in "${!HARNESS_IDS[@]}"; do
    if [ "${HARNESS_IDS[$i]}" = "$needle" ]; then echo "$i"; return 0; fi
  done
  echo "-1"
}

harness_dest() {
  local id="$1"
  case "$id" in
    claude) echo "$HOME/.claude/skills";;
    pi)     echo "$HOME/.pi/agent/skills";;
    codex)  echo "$HOME/.codex/skills";;
    gemini) echo "$HOME/.gemini/skills";;
    cursor) echo "$HOME/.cursor/skills";;
    agents) echo "$HOME/.agents/skills";;
  esac
}

# --- helpers -----------------------------------------------------------------
usage() {
  cat <<EOF
Usage: $0 [options]

Symlink skill folders from this repo into coding-harness skill directories.

Bucket options (which skill categories to install):
  --all              Install every discovered bucket without prompting
  --buckets <list>   Comma-separated buckets (e.g. engineering,personal)
  -y, --yes          Accept defaults (engineering, productivity, misc)
  --clean            Remove existing symlinks pointing into this repo first
  -n, --dry-run      Show what would happen without touching the filesystem

Harness options (where to install):
  --harness <list>   Comma-separated harness ids: claude,pi,codex,gemini,cursor,agents
                     Use "all" for every harness.
                     Default (interactive): prompts Y/n for each harness.

Misc:
  -h, --help         Show this help

Harness destinations:
  claude   → ~/.claude/skills
  pi       → ~/.pi/agent/skills
  codex    → ~/.codex/skills
  gemini   → ~/.gemini/skills
  cursor   → ~/.cursor/skills
  agents   → ~/.agents/skills  (shared – works with Pi, Gemini CLI, Cursor)

With no flags: interactive prompts for buckets and harnesses.
EOF
}

say()   { printf "%s\n" "$*"; }
warn()  { printf "warning: %s\n" "$*" >&2; }
err()   { printf "error: %s\n" "$*" >&2; }

# --- parse args --------------------------------------------------------------
MODE=interactive
SELECTION=""
CLEAN=false
DRY_RUN=false
HARNESS_MODE=interactive
HARNESS_SELECTION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)        MODE=all; shift;;
    --buckets)    MODE=explicit; SELECTION="${2:-}"; shift 2;;
    -y|--yes)     MODE=defaults; shift;;
    --clean)      CLEAN=true; shift;;
    -n|--dry-run) DRY_RUN=true; shift;;
    --harness)    HARNESS_MODE=explicit; HARNESS_SELECTION="${2:-}"; shift 2;;
    -h|--help)    usage; exit 0;;
    *) err "unknown option '$1'"; usage; exit 2;;
  esac
done

if $DRY_RUN; then PREFIX="[dry-run] "; else PREFIX=""; fi

# --- discover buckets --------------------------------------------------------
BUCKETS=()
while IFS= read -r -d '' bucket_dir; do
  if find "$bucket_dir" -name SKILL.md -not -path '*/node_modules/*' -print -quit 2>/dev/null | grep -q .; then
    BUCKETS+=("$(basename "$bucket_dir")")
  fi
done < <(find "$REPO/skills" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

if [ ${#BUCKETS[@]} -eq 0 ]; then
  err "no buckets found under $REPO/skills"
  exit 1
fi

# --- resolve harness selection -----------------------------------------------
SELECTED_HARNESSES=()

resolve_harness_ids() {
  # Accepts an id or "all".  Echoes resolved ids one per line.
  local raw="$1" id
  raw="$(printf '%s' "$raw" | tr -d '[:space:]')"
  if [ "$raw" = "all" ]; then
    for id in "${HARNESS_IDS[@]}"; do printf '%s\n' "$id"; done
    return
  fi
  local saved_ifs="$IFS"; IFS=','
  for id in $raw; do
    id="$(printf '%s' "$id" | tr -d '[:space:]')"
    [ -z "$id" ] && continue
    if [ "$(harness_index "$id")" != "-1" ]; then
      printf '%s\n' "$id"
    else
      warn "unknown harness '$id' — skipping"
    fi
  done
  IFS="$saved_ifs"
}

case "$HARNESS_MODE" in
  explicit)
    while IFS= read -r id; do
      [ -n "$id" ] && SELECTED_HARNESSES+=("$id")
    done < <(resolve_harness_ids "$HARNESS_SELECTION")
    ;;
  interactive)
    if [ ! -t 0 ] && [ ! -e /dev/tty ]; then
      err "interactive mode needs a TTY. Use --harness to specify harnesses."
      exit 2
    fi
    echo
    say "Select coding harness(es) to install into:"
    for i in "${!HARNESS_IDS[@]}"; do
      printf "  %-8s → %s\n" "${HARNESS_IDS[$i]}" "$(harness_dest "${HARNESS_IDS[$i]}")"
    done
    echo "  agents   → shared location that Pi, Gemini CLI, and Cursor all read"
    echo
    if [ -e /dev/tty ]; then exec 3</dev/tty; else exec 3<&0; fi
    for i in "${!HARNESS_IDS[@]}"; do
      hid="${HARNESS_IDS[$i]}"
      hlabel="${HARNESS_LABELS[$i]}"
      case "$hid" in
        claude|agents) prompt="  Install for ${hlabel}? [Y/n] "; def=Y;;
        *)            prompt="  Install for ${hlabel}? [y/N] "; def=N;;
      esac
      printf "%s" "$prompt"
      IFS= read -r answer <&3 || answer=""
      if [ -z "$answer" ]; then
        [ "$def" = "Y" ] && SELECTED_HARNESSES+=("$hid")
      elif [[ "$answer" =~ ^[Yy] ]]; then
        SELECTED_HARNESSES+=("$hid")
      fi
    done
    exec 3<&-
    ;;
esac

if [ ${#SELECTED_HARNESSES[@]} -eq 0 ]; then
  say "No harnesses selected — nothing to do."
  exit 0
fi

# --- resolve bucket selection ------------------------------------------------
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
      err "--buckets requires a comma-separated list"
      exit 2
    fi
    saved_ifs="$IFS"; IFS=','
    for r in $SELECTION; do
      r_trim="$(printf '%s' "$r" | tr -d '[:space:]')"
      [ -z "$r_trim" ] && continue
      matched=false
      for b in "${BUCKETS[@]}"; do
        if [ "$b" = "$r_trim" ]; then SELECTED+=("$b"); matched=true; break; fi
      done
      $matched || warn "bucket '$r_trim' not found — skipping"
    done
    IFS="$saved_ifs"
    ;;
  interactive)
    if [ ! -t 0 ] && [ ! -e /dev/tty ]; then
      err "interactive mode needs a TTY. Use --all, --yes, or --buckets."
      exit 2
    fi
    echo
    echo "Available buckets in $REPO/skills:"
    for b in "${BUCKETS[@]}"; do
      count="$(find "$REPO/skills/$b" -name SKILL.md -not -path '*/node_modules/*' | wc -l | tr -d ' ')"
      printf "  %-15s (%s skills)\n" "$b" "$count"
    done
    echo
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
  say "No buckets selected — nothing to do."
  exit 0
fi

# --- safety check: dest must not be a symlink into this repo ----------------
check_dest_safety() {
  local dest="$1"
  if [ -L "$dest" ]; then
    local resolved
    resolved="$(readlink -f "$dest" 2>/dev/null || readlink "$dest")"
    case "$resolved" in
      "$REPO"|"$REPO"/*)
        err "$dest is a symlink into this repo ($resolved)."
        err "Remove it (rm \"$dest\") and re-run; the script will recreate it as a real dir."
        exit 1
        ;;
    esac
  fi
}

for id in "${SELECTED_HARNESSES[@]}"; do
  check_dest_safety "$(harness_dest "$id")"
done

# --- clean stale symlinks (if --clean) ---------------------------------------
if $CLEAN; then
  for id in "${SELECTED_HARNESSES[@]}"; do
    local_dest="$(harness_dest "$id")"
    echo
    echo "${PREFIX}Cleaning stale symlinks pointing into $REPO from $local_dest …"
    while IFS= read -r -d '' link; do
      target="$(readlink "$link" 2>/dev/null || true)"
      case "$target" in
        "$REPO"/*)
          if $DRY_RUN; then
            echo "  ${PREFIX}would remove $(basename "$link")"
          else
            echo "  removed $(basename "$link")"
            rm "$link"
          fi
          ;;
      esac
    done < <(find "$local_dest" -maxdepth 1 -type l -print0 2>/dev/null || true)
  done
fi

# --- install -----------------------------------------------------------------
for id in "${SELECTED_HARNESSES[@]}"; do
  DEST="$(harness_dest "$id")"

  # Resolve label
  LABEL="$id"
  for ii in "${!HARNESS_IDS[@]}"; do
    if [ "${HARNESS_IDS[$ii]}" = "$id" ]; then
      LABEL="${HARNESS_LABELS[$ii]}"
      break
    fi
  done

  echo
  echo "${PREFIX}━━━ ${LABEL} → $DEST ━━━"

  if $DRY_RUN; then
    [ -d "$DEST" ] || echo "${PREFIX}would create $DEST"
  else
    mkdir -p "$DEST"
  fi

  for bucket in "${SELECTED[@]}"; do
    bucket_dir="$REPO/skills/$bucket"
    while IFS= read -r -d '' skill_md; do
      src="$(dirname "$skill_md")"
      name="$(basename "$src")"
      target="$DEST/$name"

      if $DRY_RUN; then
        if [ -e "$target" ] && [ ! -L "$target" ]; then
          printf "  %swould replace non-symlink %-25s with link to %s\n" "$PREFIX" "$name" "$bucket/$name"
        elif [ -L "$target" ] && [ "$(readlink "$target" 2>/dev/null)" = "$src" ]; then
          printf "  %sup-to-date %-30s (%s)\n" "$PREFIX" "$name" "$bucket"
        else
          printf "  %swould link %-30s (%s)\n" "$PREFIX" "$name" "$bucket"
        fi
        continue
      fi

      if [ -e "$target" ] && [ ! -L "$target" ]; then
        rm -rf "$target"
      fi

      ln -sfn "$src" "$target"
      printf "  linked %-35s (%s)\n" "$name" "$bucket"
    done < <(find "$bucket_dir" -name SKILL.md -not -path '*/node_modules/*' -print0)
  done
done

# --- summary -----------------------------------------------------------------
echo
if $DRY_RUN; then
  echo "[dry-run] No changes made. Re-run without --dry-run to apply."
else
  echo "Done. Installed ${#SELECTED[@]} bucket(s) into ${#SELECTED_HARNESSES[@]} harness(es)."
  echo
  echo "Selected harnesses:"
  for id in "${SELECTED_HARNESSES[@]}"; do
    printf "  %-8s → %s\n" "$id" "$(harness_dest "$id")"
  done
fi
