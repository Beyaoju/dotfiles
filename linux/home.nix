{
  config,
  lib,
  pkgs,
  user,
  homeDirectory,
  isOmarchy ? false,
  ...
}:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  shellAliases = {
    ".." = "cd ..";
    add = "git add .";
    push = "git push";
    pull = "git pull";
    m = "git switch main";
    cc = "claude --dangerously-skip-permissions";
    co = "codex --full-auto";
  };
in

{
  home.username = user;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep # fast search
    fd # fast find
    fzf # fuzzy finder
    jq # json on the command line
    lazygit
    nodejs
    neovim
    prettier
    unzip
    # the font everything renders in
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";

  programs.zsh = lib.mkIf (!isOmarchy) {
    enable = true;
    autosuggestion.enable = true; # ghost text from history
    syntaxHighlighting.enable = true; # commands turn green when valid
    initContent = ''
      bindkey '^f' autosuggest-accept
    '';
    inherit shellAliases;
  };

  # Omarchy uses Bash as its login shell. Load its own aliases, functions,
  # environment, completions, and Starship setup before applying local aliases.
  programs.bash = lib.mkIf isOmarchy {
    enable = true;
    bashrcExtra = ''
      if [[ $- == *i* ]]; then
        if [[ -r /usr/share/omarchy/default/bash/rc ]]; then
          [[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] \
            && source /usr/share/omarchy/default/bash/env-bootstrap
          source /usr/share/omarchy/default/bash/rc
        elif [[ -r "$HOME/.local/share/omarchy/default/bash/rc" ]]; then
          source "$HOME/.local/share/omarchy/default/bash/rc"
        fi
      fi
    '';
    inherit shellAliases;
  };

  programs.starship = {
    enable = true;
    # Omarchy's Bash initialization already starts Starship.
    enableBashIntegration = !isOmarchy;
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/ghostty".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/ghostty";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr/config.toml";
  home.file.".config/starship.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/starship.toml";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";

  # Keep Pi's credential and runtime state local by linking only authored files and directories.
  home.file.".pi/agent/themes".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/themes";
  home.file.".pi/agent/extensions".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/extensions";
  home.file.".pi/agent/models.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/models.json";
  home.file.".pi/agent/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/settings.json";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
