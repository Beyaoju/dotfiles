# dotfiles

Based on [kunchenguid/dotfiles](https://github.com/kunchenguid/dotfiles).
Watch the original walkthrough: https://youtu.be/5N-okeDdIuI

My personal Apple Silicon Mac and Framework Desktop setup.
The Mac uses nix-darwin and Home Manager. The Framework runs Omarchy and uses standalone Home Manager, leaving Arch Linux and the Omarchy desktop in charge of the system.

## Contributing / Using This Repo

These are my personal dotfiles, shared publicly so people can read them, learn from them, and fork them freely.
Feature requests and pull requests are not accepted here, and PRs are auto-closed.
If you find a bug, please open a GitHub Issue using the bug report template.

## What you get

Both machines get:

- Nix user packages (ripgrep, fd, fzf, jq, lazygit, Node.js, Neovim, Prettier, unzip, Hack Nerd Font)
- Shell aliases and a Starship prompt with the Catppuccin Mocha palette
- Editor (Neovim config with the Catppuccin Mocha theme)
- Terminal (Ghostty config with the Catppuccin Mocha theme, transparency, and background blur)
- Agent configs (Claude, Codex, opencode all share one AGENTS.md)
- Optional Pi theme and local extensions, generic UI settings and model overrides, plus two deliberately pinned third-party Pi packages

The Mac additionally gets macOS defaults and the declared Homebrew apps. The Framework keeps Omarchy's system packages, AMD drivers, Hyprland desktop, and hardware setup untouched.

## Prerequisites

- Apple Silicon Mac, by default.
- Framework Desktop with the Ryzen AI Max+ 395, including the 128 GB configuration, running Omarchy on `x86_64-linux`.
- Intel Mac: change one line.
  In `configuration.nix`, set `nixpkgs.hostPlatform = "x86_64-darwin";` (the comment right there tells you the same thing).

The Framework's 128 GB memory capacity needs no Nix setting. Omarchy owns the kernel, firmware, graphics, networking, and hardware-specific configuration.

## Fresh-machine setup

On a brand new Mac, or after completing the Omarchy installation on the Framework, start from a bare clone of this repo:

```sh
git clone https://github.com/Beyaoju/dotfiles.git
cd dotfiles
```

Before you run it: review "Make it yours" below.
Review the username and host labels below. Mac users should also read the Homebrew cleanup warning.
`bootstrap.sh` applies the config to your machine, so do this first.

```sh
./bootstrap.sh
```

`bootstrap.sh` does four things, in order:

1. Installs Determinate Nix, if it isn't already installed.
2. Symlinks this repo to `~/.dotfiles`.
   This has to happen before the first build, because `linux/home.nix` points at config files through `~/.dotfiles`.
3. Checks the `user` in both flake files against your local username and offers to update both when needed.
4. Selects the activation path by operating system:

   - macOS runs the first `darwin-rebuild switch`.
   - Linux runs standalone Home Manager from `linux/flake.nix` and backs up existing Omarchy-owned files with the `hm-backup` suffix before adopting them.

The Linux flake contains only Nixpkgs and Home Manager inputs. Omarchy does not fetch or install nix-darwin, nix-homebrew, or Homebrew.

### Validate without applying

Once Nix is installed (`bootstrap.sh` step 1 handles that), validate the matching platform without applying it:

macOS:

```sh
nix flake check --no-build
nix build .#darwinConfigurations.mac.system --dry-run
```

Framework Desktop:

```sh
nix flake check ./linux --all-systems --no-build
nix build ./linux#homeConfigurations.framework.activationPackage --dry-run
```

If you renamed a host label in "Make it yours", substitute that label in these commands.

## Daily use

Edit the config files in place, then apply:

```sh
./rebuild.sh
```

That's it.
No separate build-and-copy step.

## Make it yours

This repo is mine.
If you clone it, review these before you run `bootstrap.sh`:

- **Username**: run `./bootstrap.sh` to update both platform flakes, or edit the `user = "austinb"` lines in `flake.nix` and `linux/flake.nix` together.
  The shared Home Manager module receives the matching platform home directory from its flake.
- **Mac host label** `"mac"`: keep the name in `flake.nix`, `bootstrap.sh`, and `rebuild.sh` synchronized.
- **Framework host label** `"framework"`: keep the name in `linux/flake.nix`, `bootstrap.sh`, and `rebuild.sh` synchronized.
- **CPU architecture**, `hostPlatform` in `configuration.nix` (see Prerequisites above).

**Git identity:** this config deliberately does not set your git name or email.
Git will stop your first commit and tell you to set them (`git config --global user.name "Your Name"` and `git config --global user.email you@example.com`).
If you'd rather manage that declaratively, add this to `linux/home.nix` with your own identity:

```nix
programs.git = {
  enable = true;
  settings.user = {
    name = "Your Name";
    email = "you@example.com";
  };
};
```

**Homebrew cleanup warning for macOS:** `configuration.nix` sets `homebrew.onActivation.cleanup = "zap"`.
That means every time you switch, Homebrew removes any package or cask on your machine that isn't listed in the `brews` and `casks` arrays in `configuration.nix`.
If you already have Homebrew stuff installed that isn't in that list, the first switch will uninstall it.
Read through `brews` and `casks` before you run `bootstrap.sh` or `rebuild.sh` for the first time, and add anything you want to keep.

**About `herdr`:** it's in the `brews` list.
It's a real public Homebrew formula (`brew info herdr` finds it in homebrew-core, no tap needed), so it will install fine.
If you don't use it, just remove it from `brews` in your copy.
That package declaration is macOS-only. The shared Herdr config is ready on the Framework, but Omarchy remains responsible for installing the Linux binary.

**Heads-up:**

- `home/AGENTS.md` is my personal agent policy, and `linux/home.nix` installs it for Claude, Codex, and opencode.
  If you clone this repo, you'd silently inherit my agent instructions - edit or delete `home/AGENTS.md` if you don't want that.
- The `cc` and `co` shell aliases in `linux/home.nix` are high-agency shortcuts: `claude --dangerously-skip-permissions` and `codex --full-auto`.
  They're convenient for me, but know what they do before you use them.

## Repo tour

- `flake.nix` and `flake.lock` - the macOS-only entry point and dependency lock.
  They wire up nix-darwin, Home Manager, and nix-homebrew, and declare the `mac` machine.
- `linux/flake.nix` and `linux/flake.lock` - the Framework-only entry point and dependency lock.
  They use `x86_64-linux` Nixpkgs and standalone Home Manager, with no Darwin or Homebrew inputs.
- `configuration.nix` - system-level config: macOS defaults, Homebrew.
- `linux/home.nix` - the shared user-level config used by both platforms: shell, packages, prompt, and symlinks.
- `rebuild.sh` - re-applies the config after the first switch.
  Run this every time you make a change.
- `home/` - the actual config files that get symlinked into place; the sections below explain the shared symlink model and Pi's narrower selective setup.

## How the symlinks work

The files under `home/` are the real files - editing them here is editing your live config, no rebuild needed to see the change in your editor.
`linux/home.nix` uses `mkOutOfStoreSymlink` to point `~/.config/nvim`, `~/.config/herdr/config.toml`, and `~/.config/starship.toml` at their authored files in this repo, so they never drift out of sync.
Herdr's logs, sessions, sockets, and plugin state remain local and writable under `~/.config/herdr`.
You only run `./rebuild.sh` when you change something that isn't just a symlinked file, like a package list or a system default.

## Omarchy ownership boundary

On the Framework, this repo deliberately manages only the user environment. Omarchy continues to own Arch packages, the AMD graphics stack, Hyprland, system services, firmware, and hardware configuration.

Home Manager does adopt the authored Ghostty and Neovim directories because those are part of this personal setup. The first switch moves the existing Omarchy versions aside with `hm-backup` suffixes. It also generates `.bashrc`, `.bash_profile`, and `.profile`, while sourcing Omarchy's own Bash initialization first. Both the current `/usr/share/omarchy` layout and the older `~/.local/share/omarchy` layout are supported. Local aliases are applied afterward, and Omarchy remains responsible for initializing Starship.

Do not run Omarchy's full config reinstall after activation unless you intend to replace these Home Manager symlinks. Normal Omarchy updates do not require a dotfiles rebuild.

## Optional Pi configuration

Pi is an opt-in CLI, not a dependency this repository vendors. Install it from its owner with the [official Pi instructions](https://pi.dev), for example:

```sh
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
```

[Pi Launcher](https://github.com/kunchenguid/homebrew-tap) is also optional and installed from its owner, not declared by this config:

```sh
brew install --cask kunchenguid/tap/pi-launcher
```

Home Manager owns exactly two repository-authored Pi directories: `~/.pi/agent/themes` and `~/.pi/agent/extensions`. It also links `models.json` and `settings.json` as individual files. The local extension directory is for public, repository-authored extensions only - third-party package code never belongs there. Run `/reload` after editing a local extension or other Pi resources. The terminal-title extension shows a spinner while Pi is working, then a completion mark with the session name or current directory. The `rose-pine-moon` theme was authored clean-room from the public [Rosé Pine Moon palette](https://rosepinetheme.com/palette) and Pi's [public theme schema](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json), not from a private or live theme file.

### Pi Calm

`home/.pi/agent/extensions/calm` is a standalone local Pi extension. Home Manager's existing global extensions-directory link makes Pi auto-load it without another declaration. `/calm` toggles a conversation-only presentation mode and is off by default. Its choice is stored locally in `~/.pi/agent/calm` (or the directory selected by `PI_CODING_AGENT_DIR`), not in this repository or Home Manager. Adapted from Firstmate under the bundled MIT license, Calm imports no Firstmate modules and has no Firstmate runtime dependency.

When enabled, Calm hides collapsed thinking and the call/result shells for Pi's seven built-in tools (`read`, `bash`, `edit`, `write`, `grep`, `find`, and `ls`) without leaving blank transcript rows. During an active run it replaces Pi's working row with a two-line animated blue-water, yellow-boat widget. `/calm` restores Pi's stock rendering and preserves the existing Ctrl+O tool-expansion choice.

Calm never changes prompts, tool execution, model context, session data, or ordering. `/share` and `/export` use the complete stock transcript. Generic custom tools, images, and unsupported Pi transcript classes deliberately remain visible because Pi has no safe general-purpose transcript filter. If a future Pi release no longer exports the exact collapsed-thinking rendering seam, Calm logs one diagnostic and leaves only that adapter disabled; all other behavior remains available.

Pi's package system declares two third-party sources in the linked global `settings.json`:

- `npm:@ryan_nookpi/pi-extension-codex-fast-mode@0.2.6` - the exact public npm release from `ryan_nookpi`.
- `git:github.com/algal/pi-openai-server-compaction@c6d593087709e9481223dc6c6c2269b371b5e055` - the exact public `algal` commit for experimental OpenAI server-side compaction.

The version and commit are immutable pins, so Pi does not move them during package updates. Deliberate updates require a new source and security audit, followed by an explicit pin change in `home/.pi/agent/settings.json`. On Pi 0.82.0, global settings declarations install missing pinned packages automatically at startup. No one-time install command is required. Pi keeps the downloaded npm and git package trees in its own unmanaged `~/.pi/agent/npm` and `~/.pi/agent/git` runtime directories, outside Home Manager and Git tracking.

Both packages execute with your full user permissions and must be trusted like any other executable code. The compaction package is experimental, sends the relevant OpenAI compaction and continuity data to OpenAI, and upstream declares the stale peer range `>=0.80.9 <0.81.0`; this exact immutable ref was locally proven to load and perform remote compaction on Pi 0.82.0. Do not treat that proof as a guarantee for a different Pi version or a different package ref.

Home Manager deliberately does not manage `~/.pi/agent` itself, or Pi authentication, sessions, trust decisions, caches, npm/git package trees, or any other runtime state. The model overrides contain no credentials or endpoint settings, do not choose a default model, and only take effect after you authenticate Pi yourself. This remains an additive post-video layer: it does not install Pi, a launcher, or package source code into this repository.

## Notes

The first time you launch `nvim`, it bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim) by cloning plugins from GitHub.
That needs network access once; after that it's offline.
Neovim and Ghostty use Catppuccin Mocha.
Neovim keeps italics off and uses a transparent background on macOS, Windows, and WSL so it matches the terminal setup.

## License

This repo is licensed under MIT No Attribution.
See `LICENSE`.
