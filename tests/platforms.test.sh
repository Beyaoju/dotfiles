#!/usr/bin/env bash
# End-to-end platform routing checks for bootstrap.sh and rebuild.sh.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

dotfiles_test_tmproot TMP_ROOT platforms
FAKE_BIN="$TMP_ROOT/bin"
COMMAND_LOG="$TMP_ROOT/commands.log"

mkdir -p "$FAKE_BIN"

cat >"$FAKE_BIN/uname" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "${TEST_UNAME:?TEST_UNAME is required}"
EOF

cat >"$FAKE_BIN/whoami" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "${TEST_USER:-austinb}"
EOF

cat >"$FAKE_BIN/nix" <<'EOF'
#!/usr/bin/env bash
printf 'nix' >>"${COMMAND_LOG:?COMMAND_LOG is required}"
printf ' <%s>' "$@" >>"$COMMAND_LOG"
printf '\n' >>"$COMMAND_LOG"
EOF

cat >"$FAKE_BIN/sudo" <<'EOF'
#!/usr/bin/env bash
printf 'sudo' >>"${COMMAND_LOG:?COMMAND_LOG is required}"
printf ' <%s>' "$@" >>"$COMMAND_LOG"
printf '\n' >>"$COMMAND_LOG"
EOF

chmod +x "$FAKE_BIN/uname" "$FAKE_BIN/whoami" "$FAKE_BIN/nix" "$FAKE_BIN/sudo"

make_fixture() {
  local fixture="$TMP_ROOT/$1"
  mkdir -p "$fixture"
  cp "$ROOT/bootstrap.sh" "$ROOT/rebuild.sh" "$ROOT/flake.nix" "$fixture/"
  cp -R "$ROOT/linux" "$fixture/"
  printf '%s\n' "$fixture"
}

run_script() {
  local platform=$1 home=$2 script=$3 test_user=${4:-austinb}
  TEST_UNAME="$platform" \
    TEST_USER="$test_user" \
    COMMAND_LOG="$COMMAND_LOG" \
    HOME="$home" \
    PATH="$FAKE_BIN:/usr/bin:/bin" \
    "$script"
}

test_cross_platform_username_rewrite() {
  local fixture home output
  fixture=$(make_fixture username-rewrite)
  home="$TMP_ROOT/username-home"
  mkdir -p "$home"
  : >"$COMMAND_LOG"

  output=$(printf 'y\n' | run_script Linux "$home" "$fixture/bootstrap.sh" framework-user 2>&1) \
    || fail "username rewrite bootstrap failed: $output"
  grep -q 'user = "framework-user";' "$fixture/flake.nix" \
    || fail "bootstrap did not rewrite the macOS flake username"
  grep -q 'user = "framework-user";' "$fixture/linux/flake.nix" \
    || fail "bootstrap did not rewrite the Framework flake username"

  pass "bootstrap keeps both platform usernames synchronized"
}

test_framework_bootstrap() {
  local fixture home output commands
  fixture=$(make_fixture framework-bootstrap)
  home="$TMP_ROOT/framework-home"
  mkdir -p "$home"
  : >"$COMMAND_LOG"

  output=$(run_script Linux "$home" "$fixture/bootstrap.sh" 2>&1) \
    || fail "Framework bootstrap failed: $output"
  commands=$(cat "$COMMAND_LOG")

  [ "$(cd "$(readlink "$home/.dotfiles")" && pwd -P)" = "$(cd "$fixture" && pwd -P)" ] \
    || fail "Framework bootstrap did not create the ~/.dotfiles symlink"
  assert_contains "$commands" \
    "nix <run> <$fixture/linux#home-manager> <--> <switch> <--flake> <$home/.dotfiles/linux#framework> <-b> <hm-backup>" \
    "Framework bootstrap did not activate the locked Home Manager configuration"
  assert_not_contains "$commands" "darwin-rebuild" \
    "Framework bootstrap invoked darwin-rebuild"

  pass "Framework bootstrap installs the standalone Home Manager profile"
}

test_platform_rebuild_routing() {
  local fixture home commands output
  fixture=$(make_fixture rebuild-routing)
  home="$TMP_ROOT/rebuild-home"
  mkdir -p "$home"

  : >"$COMMAND_LOG"
  output=$(run_script Linux "$home" "$fixture/rebuild.sh" 2>&1) \
    || fail "Framework rebuild failed: $output"
  commands=$(cat "$COMMAND_LOG")
  assert_contains "$commands" \
    "nix <run> <$fixture/linux#home-manager> <--> <switch> <--flake> <$home/.dotfiles/linux#framework>" \
    "Framework rebuild did not use Home Manager"

  : >"$COMMAND_LOG"
  output=$(run_script Darwin "$home" "$fixture/rebuild.sh" 2>&1) \
    || fail "Mac rebuild failed: $output"
  commands=$(cat "$COMMAND_LOG")
  assert_contains "$commands" "sudo <darwin-rebuild> <switch> <--flake> <$home/.dotfiles#mac>" \
    "Mac rebuild no longer uses darwin-rebuild"

  if output=$(run_script FreeBSD "$home" "$fixture/rebuild.sh" 2>&1); then
    fail "rebuild.sh accepted an unsupported operating system"
  fi
  assert_contains "$output" "Unsupported operating system: FreeBSD" \
    "rebuild.sh did not explain the unsupported operating system"

  pass "rebuild routes Linux and Darwin to their own activation tools"
}

test_linux_configuration_wiring() {
  local flake home lock
  flake=$(cat "$ROOT/linux/flake.nix")
  home=$(cat "$ROOT/linux/home.nix")
  lock=$(cat "$ROOT/linux/flake.lock")

  assert_contains "$flake" 'homeConfigurations."framework"' \
    "flake.nix does not export the Framework Home Manager configuration"
  assert_contains "$flake" 'system = "x86_64-linux"' \
    "Framework configuration does not target x86_64-linux"
  # This is deliberately the literal Nix interpolation, not a shell expansion.
  # shellcheck disable=SC2016
  assert_contains "$flake" 'homeDirectory = "/home/${user}"' \
    "Framework configuration does not use a Linux home directory"
  assert_contains "$home" 'programs.bash' \
    "home.nix does not configure Omarchy's Bash shell"
  assert_contains "$home" '/usr/share/omarchy/default/bash/rc' \
    "home.nix does not preserve current Omarchy shell initialization"
  assert_contains "$home" '.local/share/omarchy/default/bash/rc' \
    "home.nix does not preserve pre-Quattro Omarchy shell initialization"
  assert_not_contains "$flake" "nix-darwin" \
    "Framework flake depends on nix-darwin"
  assert_not_contains "$lock" "nix-darwin" \
    "Framework lock contains nix-darwin"
  assert_not_contains "$lock" "nix-homebrew" \
    "Framework lock contains nix-homebrew"

  pass "Framework flake and Omarchy shell integration are wired"
}

test_framework_bootstrap
test_cross_platform_username_rewrite
test_platform_rebuild_routing
test_linux_configuration_wiring
