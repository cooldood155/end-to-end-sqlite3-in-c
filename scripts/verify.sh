#!/usr/bin/env bash
#
# Master verification entry point.
#
#   ./scripts/verify.sh list                    what can run in this shell now
#   ./scripts/verify.sh list-possible           what this machine could host
#   ./scripts/verify.sh run                     verify the runnable targets
#   ./scripts/verify.sh run-possible            queue everything possible
#   ./scripts/verify.sh run windows-ucrt64      verify one named target
#   ./scripts/verify.sh run --cross             verify every runnable cross target
#   ./scripts/verify.sh clean                   remove generated output only
#
# The -possible commands widen what is listed and queued, never what is built:
# every target still re-checks its environment strictly **before** compiling,
# so a CLANG64 target queued from a UCRT64 shell stops at the environment stage
# and won't attempt to build against the wrong toolchain.
#
# Each target runs in a subshell, so its configuration and its pass/fail
# counters cannot overwrite eachother.

set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ETESCA_REPO_ROOT="$REPO_ROOT"
export ETESCA_REPO_ROOT

# 'verify_base.sh' MUST be sourced BEFORE 'targets.sh'
# shellcheck source=helpers/verify_base.sh
source "${SCRIPT_DIR}/helpers/verify_base.sh"
# shellcheck source=helpers/targets.sh
source "${SCRIPT_DIR}/helpers/targets.sh"

usage() {
  cat <<USAGE
usage: $(basename "$0") <command> [options] [target...]

commands:
  list              list targets that can run in this shell right now
  list-possible     list targets this machine could host, ignoring which MSYS2
                    environment is active and which toolchains are installed
  run               verify targets that can run right now (default)
  run-possible      queue every target this machine could host; each still
                    refuses to build unless its environment is actually active
  clean             remove generated output only, verify nothing
  help              show this message

options for commands 'run' and 'run-possible':
  --native          only native targets
  --cross           only cross targets
  --all             both (the default)
  --keep            leave generated output in place

  Naming one or more targets selects exactly those, ignoring the filters
  above and running them even when unavailable.

examples:
  $(basename "$0") list
  $(basename "$0") run
  $(basename "$0") run --cross
  $(basename "$0") run-possible
  $(basename "$0") run windows-ucrt64 cross-x86_64-mingw-w64
USAGE
}

list_targets() {
  local record name kind verdict reason note
  printf 'host: %s %s' "$(etesca_host_platform)" "$(etesca_host_arch)"
  [[ -n "${MSYSTEM:-}" ]] && printf ' (MSYSTEM=%s)' "$MSYSTEM"
  printf '\nmode: %s\n\n' "$ETESCA_SELECT_MODE"
  printf '%-30s %-7s %-4s %s\n' "TARGET" "KIND" "RUN" "NOTE"

  while IFS= read -r record; do
    name="$(printf '%s' "$record" | cut -d'|' -f1)"
    kind="$(printf '%s' "$record" | cut -d'|' -f2)"
    verdict="$(etesca_target_availability "$name" | sed -n '1p')"
    reason="$(etesca_target_availability "$name" | sed -n '2p')"

    if [[ "$verdict" == "yes" ]]; then
      note="$(etesca_target_desc "$name")"
    else
      note="$reason"
    fi

    printf '%-30s %-7s %-4s %s\n' "$name" "$kind" "$verdict" "$note"
  done < <(etesca_target_records)
}

# Only ever returns targets whose availability *probe* passes.
targets_by_kind() {
  local want="$1" record name kind
  while IFS= read -r record; do
    name="$(printf '%s' "$record" | cut -d'|' -f1)"
    kind="$(printf '%s' "$record" | cut -d'|' -f2)"
    [[ "$want" != "any" && "$kind" != "$want" ]] && continue
    etesca_target_runnable_here "$name" && printf '%s\n' "$name"
  done < <(etesca_target_records)
}

COMMAND="${1:-run}"
[[ $# -gt 0 ]] && shift

case "$COMMAND" in
  list)          ETESCA_SELECT_MODE="strict";   list_targets; exit 0 ;;
  list-possible) ETESCA_SELECT_MODE="possible"; list_targets; exit 0 ;;
  run)           ETESCA_SELECT_MODE="strict" ;;
  run-possible)  ETESCA_SELECT_MODE="possible" ;;
  clean)         etesca_cleanup; echo "cleaned."; exit 0 ;;
  help|--help|-h) usage; exit 0 ;;
  *)
    printf 'unknown command: %s\n\n' "$COMMAND" >&2
    usage >&2
    exit 2
    ;;
esac

KIND_FILTER="any"
KEEP=0
NAMED=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --native) KIND_FILTER="native"; shift ;;
    --cross)  KIND_FILTER="cross";  shift ;;
    --all)    KIND_FILTER="any";    shift ;;
    --keep)   KEEP=1; shift ;;
    --help|-h) usage; exit 0 ;;
    -*)
      printf 'unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if ! etesca_target_exists "$1"; then
        printf 'unknown target: %s\n\n' "$1" >&2
        ETESCA_SELECT_MODE="possible" list_targets >&2
        exit 2
      fi
      if ! etesca_target_runnable_here "$1"; then
        printf 'warning: %s is not available here: %s -- ' \
          "$1" "$(etesca_target_availability "$1" | sed -n '2p')" >&2
        printf "only use if absolutely necessary\n" >&2
        printf 'running it anyway because it was named explicitly.\n\n' >&2
      fi
      NAMED="${NAMED}${1}"$'\n'
      shift
      ;;
  esac
done

if [[ -n "$NAMED" ]]; then
  SELECTED="$NAMED"
else
  SELECTED="$(targets_by_kind "$KIND_FILTER")"
fi

SELECTED="$(printf '%s' "$SELECTED" | grep -v '^$')"

if [[ -z "$SELECTED" ]]; then
  printf 'no targets selected (host %s %s, mode %s, filter %s).\n\n' \
    "$(etesca_host_platform)" "$(etesca_host_arch)" \
    "$ETESCA_SELECT_MODE" "$KIND_FILTER" >&2
  list_targets >&2
  printf '\nTry: %s run-possible\n' "$(basename "$0")" >&2
  exit 2
fi

printf '%s======== etesca verification ========%s\n' "${ETESCA_BOLD}" "${ETESCA_RESET}"
printf 'host:    %s %s\n' "$(etesca_host_platform)" "$(etesca_host_arch)"
printf 'command: %s\n' "$COMMAND"
printf 'targets:\n'
printf '%s\n' "$SELECTED" | sed 's/^/  - /'

PASSED_TARGETS=""
FAILED_TARGETS=""

while IFS= read -r target; do
  [[ -z "$target" ]] && continue

  printf '\n%s================ %s ================%s\n' \
    "${ETESCA_BOLD}" "$target" "${ETESCA_RESET}"

  # Subshell: per-target configuration and counters must not leak.
  if ( ETESCA_KEEP="$KEEP"
       etesca_target_configure "$target" || exit 1
       etesca_run_stages ); then
    PASSED_TARGETS="${PASSED_TARGETS}${target}"$'\n'
  else
    FAILED_TARGETS="${FAILED_TARGETS}${target}"$'\n'
  fi
done <<< "$SELECTED"

printf '\n%s======== Overall ========%s\n' "${ETESCA_BOLD}" "${ETESCA_RESET}"

if [[ -n "$PASSED_TARGETS" ]]; then
  printf '%spassed:%s\n' "${ETESCA_GREEN}" "${ETESCA_RESET}"
  printf '%s' "$PASSED_TARGETS" | sed 's/^/  - /'
fi

if [[ -n "$FAILED_TARGETS" ]]; then
  printf '%sfailed:%s\n' "${ETESCA_RED}" "${ETESCA_RESET}"
  printf '%s' "$FAILED_TARGETS" | sed 's/^/  - /'
fi

echo
echo "Tracked-file changes still present (should be only your own edits):"
git -C "$REPO_ROOT" status --short

echo
echo "Untracked files git clean -fd WOULD remove (nothing deleted yet):"
git -C "$REPO_ROOT" clean -nd

[[ -n "$FAILED_TARGETS" ]] && exit 1
exit 0
