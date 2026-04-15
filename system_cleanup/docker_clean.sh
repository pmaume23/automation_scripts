#!/usr/bin/env bash
# docker_clean.sh
# Safe / tiered Docker cleanup utility for macOS & Linux.
# Provides LIGHT, MEDIUM, and AGGRESSIVE cleanup levels with dry-run support.
# Goals:
#  - Avoid accidental deletion of important images or volumes
#  - Provide transparency (show what will be removed first)
#  - Allow retention window for recently used images
#  - Offer --dry-run for auditing
#  - Allow non-interactive mode with --yes

set -euo pipefail
if [[ -z "${BASH_VERSION:-}" ]]; then
	echo "[ERROR] This script requires bash. Re-run as: bash $0 ..." >&2
	exit 2
fi
IFS=$'\n\t'

VERSION="1.0.0"

COLOR_RESET='\033[0m'
COLOR_INFO='\033[1;34m'
COLOR_WARN='\033[1;33m'
COLOR_DANGER='\033[1;31m'
COLOR_OK='\033[1;32m'

_log() { printf "%b%s%b\n" "$COLOR_INFO" "$1" "$COLOR_RESET"; }
_warn() { printf "%b%s%b\n" "$COLOR_WARN" "$1" "$COLOR_RESET"; }
_danger() { printf "%b%s%b\n" "$COLOR_DANGER" "$1" "$COLOR_RESET"; }
_ok() { printf "%b%s%b\n" "$COLOR_OK" "$1" "$COLOR_RESET"; }


INTERACTIVE=false
CUSTOM=false
CUSTOM_REMOVE_CONTAINERS=true
CUSTOM_REMOVE_DANGLING_IMAGES=true
CUSTOM_REMOVE_UNUSED_IMAGES=false
CUSTOM_REMOVE_VOLUMES=false
CUSTOM_PRUNE_BUILDER=true

show_usage() {
	cat <<EOF
Docker Safe Cleanup v$VERSION

Usage: $(basename "$0") [LEVEL] [--level LEVEL|-l LEVEL|--level=LEVEL] [--retain-hours H] [--dry-run] [--yes] [--aggressive-images] [--include-volumes] [--interactive|-i] [--custom ...flags] [--help]

Levels (must choose one explicitly unless using --interactive):
	light        Remove: stopped containers, dangling images, unused networks, builder cache (safe)
	medium       light + unused images (not dangling) older than retention window
	aggressive   medium + all unused images regardless of age, optional volumes (only with --include-volumes)
	moderate     Alias for medium
	custom       Use --custom plus fine-grained flags (see below)

Custom mode flags (only with --custom):
  --no-containers           Do not remove stopped containers
  --no-dangling-images      Do not remove dangling images
  --remove-unused-images    Remove additional unused images (respecting retention unless overridden)
  --remove-volumes          Remove unused volumes
  --no-builder-cache        Skip pruning builder cache

Options:
	--retain-hours H       Minimum hours since last used to consider an image for removal (default 24 for medium, 0 for aggressive)
	--dry-run              Show what would be removed without deleting
	--yes                  Do not prompt for confirmation (non-interactive)
	--aggressive-images    In aggressive mode also remove untagged & intermediate aggressively (alias: already default for aggressive)
	--include-volumes      Allow removal of unused volumes (only effective in aggressive mode)
	--interactive,-i       Launch interactive menu to choose level or custom components
	--custom               Enable custom granular selection instead of predefined level
	--help                 Show this help

Examples:
	$0 --level light --dry-run
	$0 --level medium --retain-hours 12
	$0 --level aggressive --include-volumes --yes
EOF
}

LEVEL=""
RETAIN_HOURS=24
DRY_RUN=false
ASSUME_YES=false
INCLUDE_VOLUMES=false

## Allow first positional argument to be a level (unless custom/interactivity later)
if [[ $# -gt 0 && ! $1 =~ ^- ]]; then
	case "$1" in
		light|medium|aggressive|moderate|custom)
			LEVEL="$1"; shift;
			[[ "$LEVEL" == "custom" ]] && CUSTOM=true;;
	esac
fi

while [[ $# -gt 0 ]]; do
	case "$1" in
		--level)
			[[ $# -lt 2 ]] && { _danger "--level requires an argument"; exit 1; };
			LEVEL="$2"; shift 2;;
		--level=*)
			LEVEL="${1#*=}"; shift;;
		-l)
			[[ $# -lt 2 ]] && { _danger "-l requires an argument"; exit 1; };
			LEVEL="$2"; shift 2;;
		-l*)
			LEVEL="${1#-l}"; shift;;
		--retain-hours)
			RETAIN_HOURS="$2"; shift 2;;
		--retain-hours=*)
			RETAIN_HOURS="${1#*=}"; shift;;
		--interactive|-i)
			INTERACTIVE=true; shift;;
		--custom)
			CUSTOM=true; LEVEL="custom"; shift;;
		--no-containers)
			CUSTOM_REMOVE_CONTAINERS=false; shift;;
		--no-dangling-images)
			CUSTOM_REMOVE_DANGLING_IMAGES=false; shift;;
		--remove-unused-images)
			CUSTOM_REMOVE_UNUSED_IMAGES=true; shift;;
		--remove-volumes)
			CUSTOM_REMOVE_VOLUMES=true; shift;;
		--no-builder-cache)
			CUSTOM_PRUNE_BUILDER=false; shift;;
		--dry-run)
			DRY_RUN=true; shift;;
		--yes|-y)
			ASSUME_YES=true; shift;;
		--aggressive-images)
			shift;;
		--include-volumes)
			INCLUDE_VOLUMES=true; shift;;
		--help|-h)
			show_usage; exit 0;;
		*)
			_warn "Unknown argument: $1"; show_usage; exit 1;;
	esac
done

[[ "$LEVEL" == "moderate" ]] && LEVEL="medium"

if [[ -z "$LEVEL" && $INTERACTIVE == false ]]; then
	_warn "No level specified. Launching interactive selector (use --interactive to suppress this warning)."
	INTERACTIVE=true
fi

interactive_menu() {
	echo "Select cleanup level:" >&2
	echo "  1) light" >&2
	echo "  2) medium" >&2
	echo "  3) aggressive" >&2
	echo "  4) custom" >&2
	read -r -p "Enter choice [1-4]: " choice
	case "$choice" in
		1) LEVEL="light";;
		2) LEVEL="medium";;
		3) LEVEL="aggressive";;
		4) LEVEL="custom"; CUSTOM=true;;
		*) _warn "Invalid choice, defaulting to light"; LEVEL="light";;
	esac

	if [[ "$LEVEL" == "custom" ]]; then
		echo "Toggle components (y/n):" >&2
		read -r -p "Remove stopped containers? [Y/n]: " ans; [[ "$ans" =~ ^[Nn]$ ]] && CUSTOM_REMOVE_CONTAINERS=false
		read -r -p "Remove dangling images? [Y/n]: " ans; [[ "$ans" =~ ^[Nn]$ ]] && CUSTOM_REMOVE_DANGLING_IMAGES=false
		read -r -p "Remove other unused images (respect retention)? [y/N]: " ans; [[ "$ans" =~ ^[Yy]$ ]] && CUSTOM_REMOVE_UNUSED_IMAGES=true
		read -r -p "Remove unused volumes? [y/N]: " ans; [[ "$ans" =~ ^[Yy]$ ]] && CUSTOM_REMOVE_VOLUMES=true
		read -r -p "Prune builder cache? [Y/n]: " ans; [[ "$ans" =~ ^[Nn]$ ]] && CUSTOM_PRUNE_BUILDER=false
	fi
}

if $INTERACTIVE; then
	interactive_menu
fi

if [[ -z "$LEVEL" ]]; then
	_danger "No level selected (this should have been set by interactive prompt)."; exit 1
fi

if [[ "$LEVEL" == "custom" ]]; then
	: # skip standard validation; custom mode controls granular actions
else
	case "$LEVEL" in
		light|medium|aggressive) :;;
		*) _danger "Invalid level: $LEVEL"; show_usage; exit 1;;
	esac
fi

if ! command -v docker >/dev/null 2>&1; then
	_danger "Docker CLI not found in PATH."; exit 1
fi

_log "Requested level: $LEVEL"
_log "Dry run: $DRY_RUN"
if [[ "$LEVEL" == "custom" ]]; then
	_log "Custom components: containers=$CUSTOM_REMOVE_CONTAINERS dangling_images=$CUSTOM_REMOVE_DANGLING_IMAGES unused_images=$CUSTOM_REMOVE_UNUSED_IMAGES volumes=$CUSTOM_REMOVE_VOLUMES builder_cache=$CUSTOM_PRUNE_BUILDER"
fi

confirm() {
	local prompt="$1" reply
	if $ASSUME_YES; then return 0; fi
	read -r -p "$prompt [y/N]: " reply || return 1
	[[ "$reply" =~ ^[Yy]$ ]]
}

# Collect items (all non-destructive). NOTE: previously we mistakenly used a destructive builder prune here.
to_remove_containers=$(docker ps -a -q -f status=exited -f status=dead || true)
to_remove_networks=$(docker network ls --filter "dangling=true" -q || true)
to_remove_dangling_images=$(docker images -f dangling=true -q || true)

# Try to estimate builder cache size (best-effort). This is informational only.
builder_cache_size=""
if command -v docker >/dev/null 2>&1 && docker buildx version >/dev/null 2>&1; then
	# Parse output of `docker buildx du` if available (non-destructive)
	if docker buildx du >/dev/null 2>&1; then
		builder_cache_size=$(docker buildx du 2>/dev/null | awk 'BEGIN{total=0} /[0-9]+(\.[0-9]+)?[kMG]B/{last=$NF} END{print last}')
	fi
fi

# Medium / Aggressive images selection
candidate_images=""
if [[ "$LEVEL" != "light" ]]; then
	# List all images (id|createdSinceHours|repo:tag|size)
	# We'll approximate age by CreatedSince human string; better to use inspect for last used but not directly available.
	# Use filter by dangling=false and not currently used by any container.
	all_images=$(docker images --format '{{.ID}} {{.Repository}}:{{.Tag}} {{.CreatedAt}}')
	running_image_ids=$(docker ps --format '{{.Image}}' | xargs -I{} docker images --no-trunc --format '{{.ID}} {{.Repository}}:{{.Tag}}' | awk '{print $1}' 2>/dev/null | sort | uniq || true)
	now_epoch=$(date +%s)
	while IFS= read -r line; do
		[[ -z "$line" ]] && continue
		img_id=$(awk '{print $1}' <<<"$line")
		ref=$(awk '{print $2}' <<<"$line")
		created_at=$(awk '{print $3" "$4" "$5" "$6" "$7}' <<<"$line")
		created_epoch=$(date -j -f '%Y-%m-%d %H:%M:%S %Z' "$created_at" +%s 2>/dev/null || date -d "$created_at" +%s 2>/dev/null || echo 0)
		age_hours=$(( (now_epoch - created_epoch) / 3600 ))
		if grep -q "$img_id" <<<"$running_image_ids"; then
			continue
		fi
		if [[ "$LEVEL" == "medium" && $age_hours -lt $RETAIN_HOURS ]]; then
			continue
		fi
		candidate_images+="$img_id $ref ($age_hours h)\n"
	done <<<"$all_images"
fi

unused_volumes=""
if [[ "$LEVEL" == "aggressive" && $INCLUDE_VOLUMES == true ]]; then
	unused_volumes=$(docker volume ls -qf dangling=true || true)
fi

echo
_log "Summary (preview):"
printf "  Stopped containers: %s\n" "$(wc -w <<<"$to_remove_containers" | tr -d ' ')"
printf "  Dangling images:    %s\n" "$(wc -w <<<"$to_remove_dangling_images" | tr -d ' ')"
if [[ -n "$builder_cache_size" ]]; then
	printf "  Builder cache size: %s (will prune)\n" "$builder_cache_size"
fi
if [[ "$LEVEL" != "light" && "$LEVEL" != "custom" ]]; then
	medium_count=$(printf "%s" "$candidate_images" | grep -c '^' || true)
	printf "  Candidate images (%s level): %d\n" "$LEVEL" "$medium_count"
fi
if [[ "$LEVEL" == "custom" && $CUSTOM_REMOVE_UNUSED_IMAGES == true ]]; then
	medium_count=$(printf "%s" "$candidate_images" | grep -c '^' || true)
	printf "  Candidate images (custom unused): %d\n" "$medium_count"
fi
if [[ "$LEVEL" == "aggressive" && $INCLUDE_VOLUMES == true ]]; then
	printf "  Unused volumes:     %s\n" "$(wc -w <<<"$unused_volumes" | tr -d ' ')"
fi
if [[ "$LEVEL" == "custom" && $CUSTOM_REMOVE_VOLUMES == true ]]; then
	unused_volumes=$(docker volume ls -qf dangling=true || true)
	printf "  Unused volumes:     %s\n" "$(wc -w <<<"$unused_volumes" | tr -d ' ')"
fi

if $DRY_RUN; then
	_warn "Dry run enabled. No changes will be made."
fi

echo
_log "Details:"
[[ -n "$to_remove_containers" ]] && echo "Containers:" && docker ps -a -f status=exited -f status=dead --format '  {{.ID}} {{.Names}} {{.Status}}'
[[ -n "$to_remove_dangling_images" ]] && echo "Dangling images:" && docker images -f dangling=true --format '  {{.ID}} {{.Repository}}:{{.Tag}} {{.Size}}'
if [[ "$LEVEL" != "light" && "$LEVEL" != "custom" ]]; then
	if [[ -n "$candidate_images" ]]; then
		echo "Removable images (filtered by retention $RETAIN_HOURS h for medium, all for aggressive):"
		printf '%s' "$candidate_images" | sed 's/^/  /'
	fi
fi
if [[ "$LEVEL" == "custom" && $CUSTOM_REMOVE_UNUSED_IMAGES == true && -n "$candidate_images" ]]; then
  echo "Removable images (custom unused images set, retention $RETAIN_HOURS h):"
  printf '%s' "$candidate_images" | sed 's/^/  /'
fi
if [[ "$LEVEL" == "aggressive" && $INCLUDE_VOLUMES == true && -n "$unused_volumes" ]]; then
	echo "Volumes to remove:"; printf '%s\n' "$unused_volumes" | sed 's/^/  /'
fi
if [[ "$LEVEL" == "custom" && $CUSTOM_REMOVE_VOLUMES == true && -n "$unused_volumes" ]]; then
  echo "Volumes to remove:"; printf '%s\n' "$unused_volumes" | sed 's/^/  /'
fi

if $DRY_RUN; then
	_ok "Dry run complete."; exit 0
fi

if ! confirm "Proceed with deletion?"; then
	_warn "Aborted by user."; exit 1
fi

if { [[ "$LEVEL" == "custom" && $CUSTOM_REMOVE_CONTAINERS == true ]] || [[ "$LEVEL" != "custom" ]]; }; then
	_log "Removing stopped containers..."
	if [[ -n "$to_remove_containers" ]]; then
	  docker rm $to_remove_containers >/dev/null
	fi
else
	_log "Skipping stopped containers (custom selection)"
fi

if { [[ "$LEVEL" == "custom" && $CUSTOM_REMOVE_DANGLING_IMAGES == true ]] || [[ "$LEVEL" != "custom" ]]; }; then
	_log "Removing dangling images..."
	if [[ -n "$to_remove_dangling_images" ]]; then
	  docker rmi $to_remove_dangling_images >/dev/null || true
	fi
else
	_log "Skipping dangling images (custom selection)"
fi

if { [[ "$LEVEL" != "light" && "$LEVEL" != "custom" && -n "$candidate_images" ]] || [[ "$LEVEL" == "custom" && $CUSTOM_REMOVE_UNUSED_IMAGES == true && -n "$candidate_images" ]]; }; then
  _danger "Removing additional unused images (mode $LEVEL)..."
  image_ids=$(printf '%s' "$candidate_images" | awk '{print $1}' | sort -u)
  docker rmi $image_ids >/dev/null || true
fi

if { [[ "$LEVEL" == "aggressive" && $INCLUDE_VOLUMES == true && -n "$unused_volumes" ]] || [[ "$LEVEL" == "custom" && $CUSTOM_REMOVE_VOLUMES == true && -n "$unused_volumes" ]]; }; then
  _danger "Removing unused volumes..."
  docker volume rm $unused_volumes >/dev/null || true
fi

if { [[ "$LEVEL" == "custom" && $CUSTOM_PRUNE_BUILDER == true ]] || [[ "$LEVEL" != "custom" ]]; }; then
	_log "Pruning builder cache (safe)..."
	docker builder prune -f >/dev/null || true
else
	_log "Skipping builder cache prune (custom selection)"
fi

_ok "Docker cleanup complete. Current disk usage:"
docker system df

exit 0
