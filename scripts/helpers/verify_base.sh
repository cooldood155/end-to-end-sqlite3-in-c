#!/usr/bin/env bash
# shellcheck shell=bash
#
# Platform-neutral base paired with a verification script buit ontop of it.
# Kept compatible with bash 3.2 because that is what macOS still ships as
# /bin/bash:
#   - no associative arrays
#   - no readarray/mapfile
#   - no [[ -v ]]
#   - no ${var,,} lowercase expansion
#
# A caller sets only what its target needs, then calls 'etesca_run_stages'. The
# stage lists **are data**, so a cross target that cannot execute what it builds
# names fewer stages rather than setting skip flags everywhere.
#
# Stages come in three lists:
#   ETESCA_SETUP_STAGES   once, before anything is built
#   ETESCA_TYPE_STAGES    once per entry in ETESCA_BUILD_TYPES, as a pipeline
#   ETESCA_FINAL_STAGES   once, after every build type
#
# Nothing is ever built in a build type that was not asked for.

[[ -n "${ETESCA_VERIFY_BASE_SOURCED:-}" ]] && return 0
ETESCA_VERIFY_BASE_SOURCED=1

set -u -o pipefail

: "${ETESCA_REPO_ROOT:=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
: "${ETESCA_CONSUMER_DIR:=${TMPDIR:-/tmp}/etesca-consumer}"
: "${ETESCA_PLATFORM_LABEL:=$(uname -s 2>/dev/null || echo unknown) $(uname -m 2>/dev/null || echo unknown)}"

: "${ETESCA_BUILD_PROFILE:=${ETESCA_REPO_ROOT}/profiles/native}"
: "${ETESCA_HOST_PROFILE:=}"

: "${ETESCA_BUILD_TYPES:=Debug Release}"
: "${ETESCA_PRESET_PREFIX:=native}"
: "${ETESCA_HOST_TOOLS_PRESET:=host-tools}"

: "${ETESCA_RESULTS_FILE:=}"

: "${ETESCA_LIBRARY_TYPES:=
    STATIC
    SHARED
    STATIC+SHARED}"

: "${ETESCA_REQUIRED_TOOLS:=
    conan
    cmake
    ctest
    ninja
    git}"

: "${ETESCA_SETUP_STAGES:=
    environment
    clean_slate}"

: "${ETESCA_TYPE_STAGES:=
    workflow
    library_matrix
    auto_discovery
    install
    consumer
    cpack
    host_tools}"

: "${ETESCA_FINAL_STAGES:=
    reset}"

ETESCA_BUILD_TYPE=""
ETESCA_PRESET=""
ETESCA_SETUP_FAILED=0

if [[ -z "${ETESCA_EXE_SUFFIX+x}" ]]; then
  case "$(uname -s 2>/dev/null || echo unknown)" in
    MINGW*|MSYS*|CYGWIN*) ETESCA_EXE_SUFFIX=".exe" ;;
    *) ETESCA_EXE_SUFFIX="" ;;
  esac
fi

etesca_have_function() { declare -f "$1" >/dev/null 2>&1; }
etesca_have() { command -v "$1" >/dev/null 2>&1; }

etesca_preset_for() {
  printf '%s-%s\n' "$ETESCA_PRESET_PREFIX" \
    "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
}

etesca_clean_paths() {
  printf '%s\n' \
    "${ETESCA_REPO_ROOT}/build" \
    "${ETESCA_REPO_ROOT}/stage" \
    "${ETESCA_REPO_ROOT}/_install" \
    "${ETESCA_REPO_ROOT}/compile_commands.json" \
    "${ETESCA_REPO_ROOT}/src/etesca/scratch" \
    "${ETESCA_CONSUMER_DIR}"
}

# -----------------------------------------------------------------------------
# Hooks
# -----------------------------------------------------------------------------
# Override any of these in the platform script.
# Each default is a no-op or a generic implementation, everything is optional.

# Extra environment assertions. Return non-zero to abort the whole run: use
# this only for conditions that make every later stage meaningless/impossible.
etesca_platform_check() { return 0; }

# Runs after the environment stage, before anything is built.
etesca_platform_setup() { return 0; }

# Runs at the very end, before the summary.
etesca_platform_teardown() { return 0; }

# Files that must exist under stage/ after installing.
# Override when a platform installs a different set.
etesca_expected_install_files() {
  printf '%s\n' \
    "lib/cmake/etesca/etescaConfig.cmake" \
    "lib/cmake/etesca/etescaConfigVersion.cmake" \
    "lib/cmake/etesca/etescaTargets.cmake" \
    "lib/pkgconfig/etesca.pc"
}

if [[ -t 1 ]]; then
  ETESCA_BOLD=$'\033[1m'
  ETESCA_RED=$'\033[31m'
  ETESCA_GREEN=$'\033[32m'
  ETESCA_YELLOW=$'\033[33m'
  ETESCA_RESET=$'\033[0m'
else
  ETESCA_BOLD=""; ETESCA_RED=""; ETESCA_GREEN=""; ETESCA_YELLOW=""; ETESCA_RESET=""
fi

ETESCA_STAGE_NUMBER=0
ETESCA_PASS_COUNT=0
ETESCA_SKIP_COUNT=0
ETESCA_FAILURES=""

etesca_stage() {
  local tag=""
  [[ -n "$ETESCA_BUILD_TYPE" ]] && tag="[${ETESCA_BUILD_TYPE}] "
  ETESCA_STAGE_NUMBER=$((ETESCA_STAGE_NUMBER + 1))
  printf '\n%s---- %d. %s%s ----%s\n' \
    "$ETESCA_BOLD" "$ETESCA_STAGE_NUMBER" "$tag" "$1" "$ETESCA_RESET"
}

etesca_pass() {
  printf '%sOK%s    %s\n' "$ETESCA_GREEN" "$ETESCA_RESET" "$1"
  ETESCA_PASS_COUNT=$((ETESCA_PASS_COUNT + 1))
}

etesca_fail() {
  local entry="$1"
  [[ -n "$ETESCA_BUILD_TYPE" ]] && entry="[${ETESCA_BUILD_TYPE}] $1"
  printf '%sFAIL%s  %s\n' "$ETESCA_RED" "$ETESCA_RESET" "$1"
  ETESCA_FAILURES="${ETESCA_FAILURES}${entry}"$'\n'
  return 1
}

etesca_skip() {
  printf '%sSKIP%s  %s\n' "$ETESCA_YELLOW" "$ETESCA_RESET" "$1"
  ETESCA_SKIP_COUNT=$((ETESCA_SKIP_COUNT + 1))
}

# Records a failure but will never abort!
etesca_try() {
  local label="$1"; shift
  if "$@"; then
    etesca_pass "$label"
    return 0
  fi
  etesca_fail "$label"
  return 1
}

# Conan owns build/<BuildType>/ and CMake owns build/<presetName>/. Deleting
# the build/ directory therefore invalidates every preset's toolchainFile. Any
# stage that does so must call this again before configuring.
etesca_conan_install() {
  if [[ -n "$ETESCA_HOST_PROFILE" ]]; then
    conan install "$ETESCA_REPO_ROOT" \
      -pr:b "$ETESCA_BUILD_PROFILE" -pr:h "$ETESCA_HOST_PROFILE" \
      -s build_type="$1" --build=missing
  else
    conan install "$ETESCA_REPO_ROOT" -pr:a "$ETESCA_BUILD_PROFILE" \
      -s build_type="$1" --build=missing
  fi
}

etesca_configure_host_tools() {
  cmake --preset "$ETESCA_HOST_TOOLS_PRESET" \
    -DCMAKE_BUILD_TYPE="$ETESCA_BUILD_TYPE" \
    -DCMAKE_TOOLCHAIN_FILE="${ETESCA_REPO_ROOT}/build/${ETESCA_BUILD_TYPE}/generators/conan_toolchain.cmake"
}

etesca_conan_install_logged() {
  local log="$1" build_type="$2"
  etesca_conan_install "$build_type" 2>&1 | tee "$log"
}

etesca_cleanup() {
  local path
  while IFS= read -r path; do
    rm -rf "$path"
  done < <(etesca_clean_paths)
}

# -----------------------------------------------------------------------------
# Setup stages
# -----------------------------------------------------------------------------

etesca_stage_environment() {
  etesca_stage "Environment"
  printf 'target:   %s\n' "$ETESCA_PLATFORM_LABEL"
  printf 'build:    %s\n' "$(basename "$ETESCA_BUILD_PROFILE")"
  if [[ -n "$ETESCA_HOST_PROFILE" ]]; then
    printf 'host:     %s\n' "$(basename "$ETESCA_HOST_PROFILE")"
  fi
  printf 'types:    %s\n' "$ETESCA_BUILD_TYPES"

  local tool
  for tool in $ETESCA_REQUIRED_TOOLS; do
    if etesca_have "$tool"; then
      etesca_pass "found $tool"
    else
      etesca_fail "missing $tool"
      return 1
    fi
  done

  etesca_platform_check || return 1
  etesca_platform_setup
}

etesca_stage_clean_slate() {
  etesca_stage "Clean slate"
  etesca_cleanup
  etesca_pass "removed generated output"
}

# -----------------------------------------------------------------------------
# Per-type stages: use ETESCA_BUILD_TYPE and ETESCA_PRESET
# -----------------------------------------------------------------------------

etesca_stage_workflow() {
  etesca_stage "Workflow"

  local conan_log
  conan_log="$(mktemp "${TMPDIR:-/tmp}/etesca-conan.XXXXXX")" || return 1

  if ! etesca_try "conan install (${ETESCA_BUILD_TYPE})" \
      etesca_conan_install_logged "$conan_log" "$ETESCA_BUILD_TYPE"; then
    rm -f "$conan_log"
    return 1
  fi

  # if 'tools.build:skip_test=True' is given to Conan in anyway then it sets
  # ETESCA_BUILD_TESTS=OFF skipping add_subdirectory(tests) and responds with
  # "No tests were found" instead of an error.
  if grep -q 'ETESCA_BUILD_TESTS=OFF' "$conan_log"; then
    etesca_fail "ETESCA_BUILD_TESTS=OFF -- check tools.build:skip_test in your default profile"
  else
    etesca_pass "ETESCA_BUILD_TESTS is ON"
  fi
  rm -f "$conan_log"

  etesca_try "workflow ${ETESCA_PRESET}" cmake --workflow --preset "$ETESCA_PRESET"
}

etesca_stage_host_tools_for_cross() {
  etesca_stage "Host tools for cross"

  etesca_try "conan install (${ETESCA_BUILD_TYPE}, native)" \
    conan install "$ETESCA_REPO_ROOT" -pr:a "${ETESCA_REPO_ROOT}/profiles/native" \
      -s build_type="$ETESCA_BUILD_TYPE" --build=missing || return 1

  rm -rf "${ETESCA_REPO_ROOT}/build/${ETESCA_HOST_TOOLS_PRESET}"
  etesca_try "configure ${ETESCA_HOST_TOOLS_PRESET} (${ETESCA_BUILD_TYPE})" \
    etesca_configure_host_tools || return 1
  etesca_try "build ${ETESCA_HOST_TOOLS_PRESET} (${ETESCA_BUILD_TYPE})" \
    cmake --build "build/${ETESCA_HOST_TOOLS_PRESET}"
}

# Cross targets have no test preset and cannot run what they produce, all they
# do is configure and build rather than running a workflow and testing etc.
etesca_stage_cross_build() {
  etesca_stage "Cross configure and build"

  etesca_try "conan install (${ETESCA_BUILD_TYPE})" \
    etesca_conan_install "$ETESCA_BUILD_TYPE" || return 1
  etesca_try "configure ${ETESCA_PRESET}" cmake --preset "$ETESCA_PRESET" || return 1
  etesca_try "build ${ETESCA_PRESET}" cmake --build "build/${ETESCA_PRESET}"
}

etesca_stage_library_matrix() {
  etesca_stage "Library type matrix"

  local library_type
  for library_type in $ETESCA_LIBRARY_TYPES; do
    printf -- '  -- %s --\n' "$library_type"
    rm -rf "${ETESCA_REPO_ROOT}/build/${ETESCA_PRESET}"

    etesca_try "configure $library_type" cmake --preset "$ETESCA_PRESET" \
      -DETESCA_LIBRARY_TYPE="$library_type" || continue
    etesca_try "build $library_type" \
      cmake --build "build/${ETESCA_PRESET}" || continue

    if [[ -n "$ETESCA_HOST_PROFILE" ]]; then
      etesca_skip "ctest $library_type (cross target, binaries not runnable here)"
      continue
    fi

    etesca_try "ctest $library_type" \
      ctest --test-dir "build/${ETESCA_PRESET}" --output-on-failure
  done
}

etesca_stage_auto_discovery() {
  etesca_stage "Auto-discovery"

  local scratch="${ETESCA_REPO_ROOT}/src/etesca/scratch"
  mkdir -p "$scratch"
  printf 'namespace etesca { int scratch_probe() { return 1; } }\n' > "$scratch/probe.cpp"

  local log
  log="$(cmake --build "build/${ETESCA_PRESET}" 2>&1)"
  printf '%s\n' "$log"

  if printf '%s' "$log" | grep -q 'probe\.cpp'; then
    etesca_pass "new source compiled without editing CMake"
  else
    etesca_fail "probe.cpp was not picked up -- CONFIGURE_DEPENDS is not working"
  fi

  rm -rf "$scratch"
  etesca_try "rebuild after removing the probe" \
    cmake --build "build/${ETESCA_PRESET}"
}

etesca_stage_install() {
  etesca_stage "Install and package metadata"

  rm -rf "${ETESCA_REPO_ROOT}/build/${ETESCA_PRESET}" "${ETESCA_REPO_ROOT}/stage"

  etesca_try "configure ${ETESCA_PRESET}" cmake --preset "$ETESCA_PRESET" || return 1
  etesca_try "build ${ETESCA_PRESET}" cmake --build "build/${ETESCA_PRESET}" || return 1
  etesca_try "install ${ETESCA_PRESET}" cmake --install "build/${ETESCA_PRESET}" \
    --prefix "${ETESCA_REPO_ROOT}/stage" || return 1

  find "${ETESCA_REPO_ROOT}/stage" -type f | sort

  local expected
  while IFS= read -r expected; do
    if [[ -f "${ETESCA_REPO_ROOT}/stage/${expected}" ]]; then
      etesca_pass "installed ${expected}"
    else
      etesca_fail "missing ${expected}"
    fi
  done < <(etesca_expected_install_files)

  local pc="${ETESCA_REPO_ROOT}/stage/lib/pkgconfig/etesca.pc"
  if [[ -f "$pc" ]]; then
    cat "$pc"
    if etesca_have pkg-config; then
      etesca_try "pkg-config reads etesca.pc" env \
        PKG_CONFIG_PATH="${ETESCA_REPO_ROOT}/stage/lib/pkgconfig" \
        pkg-config --cflags --libs etesca
    else
      etesca_skip "pkg-config not installed"
    fi
  fi
}

etesca_stage_consumer() {
  etesca_stage "Consumer project"

  # This project **only ever** sees installed files!
  if [[ ! -f "${ETESCA_REPO_ROOT}/stage/lib/cmake/etesca/etescaConfig.cmake" ]]; then
    etesca_skip "no etescaConfig.cmake was installed"
    return 0
  fi

  rm -rf "$ETESCA_CONSUMER_DIR"
  mkdir -p "$ETESCA_CONSUMER_DIR"

  cat > "$ETESCA_CONSUMER_DIR/CMakeLists.txt" <<'CONSUMER_CMAKE'
cmake_minimum_required(VERSION 3.30)
project(consumer LANGUAGES CXX)
find_package(etesca REQUIRED)
add_executable(consumer main.cpp)
target_link_libraries(consumer PRIVATE etesca::etesca)
CONSUMER_CMAKE

  cat > "$ETESCA_CONSUMER_DIR/main.cpp" <<'CONSUMER_MAIN'
#include <etesca/core.hpp>
#include <cstdio>
int main() { std::printf("%s\n", etesca::version()); return 0; }
CONSUMER_MAIN

  etesca_try "configure consumer (${ETESCA_BUILD_TYPE})" cmake -S "$ETESCA_CONSUMER_DIR" \
    -B "$ETESCA_CONSUMER_DIR/b" -G Ninja \
    -DCMAKE_BUILD_TYPE="$ETESCA_BUILD_TYPE" \
    -DCMAKE_PREFIX_PATH="${ETESCA_REPO_ROOT}/stage" || return 1
  etesca_try "build consumer (${ETESCA_BUILD_TYPE})" \
    cmake --build "$ETESCA_CONSUMER_DIR/b" || return 1
  etesca_try "run consumer (${ETESCA_BUILD_TYPE})" \
    "${ETESCA_CONSUMER_DIR}/b/consumer${ETESCA_EXE_SUFFIX}"
}

etesca_stage_cpack() {
  etesca_stage "CPack"

  local build_dir="${ETESCA_REPO_ROOT}/build/${ETESCA_PRESET}"
  if [[ ! -d "$build_dir" ]]; then
    etesca_skip "no build tree for ${ETESCA_PRESET}"
    return 0
  fi

  if ( cd "$build_dir" && cpack && cpack --config CPackSourceConfig.cmake ); then
    etesca_pass "cpack binary and source packages (${ETESCA_PRESET})"
    ls -1 "$build_dir"/*.tar.gz "$build_dir"/*.zip 2>/dev/null
  else
    etesca_fail "cpack (${ETESCA_PRESET})"
  fi
}

etesca_stage_host_tools() {
  etesca_stage "Host tools only"

  # Ensures ETESCA_LIBRARY_TYPE=NONE is properly guarded within the project.
  rm -rf "${ETESCA_REPO_ROOT}/build/${ETESCA_HOST_TOOLS_PRESET}"
  etesca_try "configure ${ETESCA_HOST_TOOLS_PRESET} (${ETESCA_BUILD_TYPE})" \
    etesca_configure_host_tools || return 1
  etesca_try "build ${ETESCA_HOST_TOOLS_PRESET} (${ETESCA_BUILD_TYPE})" \
    cmake --build "build/${ETESCA_HOST_TOOLS_PRESET}"
}

# -----------------------------------------------------------------------------
# Final stages
# -----------------------------------------------------------------------------

etesca_stage_reset() {
  etesca_stage "Reset"

  if [[ "${ETESCA_KEEP:-0}" -eq 1 ]]; then
    echo "--keep given: leaving generated output in place."
  else
    etesca_cleanup
    etesca_pass "removed generated output"
  fi
}

# -----------------------------------------------------------------------------
# Driver
# -----------------------------------------------------------------------------

etesca_target_summary() {
  printf '\n%s---- %s ----%s\n' "$ETESCA_BOLD" "$ETESCA_PLATFORM_LABEL" "$ETESCA_RESET"
  printf 'passed: %d  skipped: %d\n' "$ETESCA_PASS_COUNT" "$ETESCA_SKIP_COUNT"

  local build_type count result
  for build_type in $ETESCA_BUILD_TYPES; do
    if [[ "$ETESCA_SETUP_FAILED" -eq 1 ]]; then
      result="not run"
    else
      count="$(printf '%s' "$ETESCA_FAILURES" | grep -c "^\[${build_type}\] ")"
      if [[ "$count" -eq 0 ]]; then
        result="passed"
      else
        result="failed (${count})"
      fi
    fi

    printf '  %-16s %s\n' "$build_type" "$result"
    if [[ -n "$ETESCA_RESULTS_FILE" ]]; then
      printf '%s|%s|%s\n' "${ETESCA_TARGET_NAME:-unknown}" "$build_type" "$result" \
        >> "$ETESCA_RESULTS_FILE"
    fi
  done

  if [[ -n "$ETESCA_FAILURES" ]]; then
    printf '%sfailures:%s\n' "$ETESCA_RED" "$ETESCA_RESET"
    printf '%s' "$ETESCA_FAILURES" | while IFS= read -r failure; do
      [[ -n "$failure" ]] && printf '  - %s\n' "$failure"
    done
    return 1
  fi

  printf '%sall stages passed%s\n' "$ETESCA_GREEN" "$ETESCA_RESET"
  return 0
}

etesca_run_stage_list() {
  local stage_name
  for stage_name in $1; do
    if ! etesca_have_function "etesca_stage_${stage_name}"; then
      etesca_fail "unknown stage '${stage_name}'"
      continue
    fi

    "etesca_stage_${stage_name}"

    if [[ "$stage_name" == "environment" && -n "$ETESCA_FAILURES" ]]; then
      return 1
    fi
  done
  return 0
}

etesca_run_stages() {
  cd "$ETESCA_REPO_ROOT" || return 1

  if etesca_run_stage_list "$ETESCA_SETUP_STAGES"; then
    local build_type
    for build_type in $ETESCA_BUILD_TYPES; do
      ETESCA_BUILD_TYPE="$build_type"
      ETESCA_PRESET="$(etesca_preset_for "$build_type")"
      etesca_run_stage_list "$ETESCA_TYPE_STAGES"
    done

    ETESCA_BUILD_TYPE=""
    ETESCA_PRESET=""
    etesca_run_stage_list "$ETESCA_FINAL_STAGES"
  else
    ETESCA_SETUP_FAILED=1
  fi

  etesca_platform_teardown
  etesca_target_summary
}
