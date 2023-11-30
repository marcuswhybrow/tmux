{
  description = "Tmux terminal multiplexer configured by Marcus";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    fish.url = "github:marcuswhybrow/fish";
  };

  outputs = inputs: let
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    fish = "${inputs.fish.packages.x86_64-linux.fish}/bin/fish";
    wrapper = pkgs.runCommand "tmux-wrapper" {
      nativeBuildInputs = [ pkgs.makeWrapper ];
    } ''
      mkdir --parents $out/share
      tee $out/share/tmux.conf << EOF
        run-shell ${pkgs.tmuxPlugins.catppuccin.rtp}
        set -g @catppuccin_flavour 'latte'
        set -g @catppuccin_window_tabs_enabled on
        set -g @catppuccin_date_time "%H:%M"

        bind r source-file $out/share/tmux.conf

        set -g default-command "${fish}"

        set -g prefix C-space
        unbind C-b
        bind C-space send-prefix

        # Pane splitting
        bind C-h split-window -h -b  # left
        bind C-j split-window -v     # down
        bind C-k split-window -v -b  # up
        bind C-l split-window -h     # right
        unbind '"'                   # old vertical
        unbind '%'                   # old horizontal

        # Pane switching
        bind h select-pane -L        # left
        bind j select-pane -D        # down
        bind k select-pane -U        # up
        bind l select-pane -R        # right

        # Mouse control
        set -g mouse on

        # Tmux Windows (Now Microsoft Windows)
        set-option -g allow-rename off

        # Fix neovim colors look wrong inside tmux (https://stackoverflow.com/questions/60309665)
        set-option -sa terminal-features ',xterm-256color:RGB'

        # Advice from neovim :checkhealth ("autoread" may not work)
        set-option -g focus-events on

        # Advice from neovim :checkhealth
        set-option -sg escape-time 20
      EOF


      mkdir --parents $out/bin
      makeWrapper ${pkgs.tmux}/bin/tmux $out/bin/tmux \
        --add-flags "-f $out/share/tmux.conf"
    '';
  in {
    packages.x86_64-linux.tmux = pkgs.symlinkJoin {
      name = "tmux";
      paths = [ wrapper pkgs.tmux ]; # firt ./bin/tmux has precedence
    };

    packages.x86_64-linux.default = inputs.self.packages.x86_64-linux.tmux;
  };
}
