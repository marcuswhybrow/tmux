{
  description = "Tmux terminal multiplexer configured by Marcus";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    fish.url = "github:marcuswhybrow/fish";
  };

  outputs = inputs: let
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    fish = "${inputs.fish.packages.x86_64-linux.fish}/bin/fish";
    getConf = pkgs.writeShellScript "get-conf" ''
      tmuxBin=$(which tmux)
      nixStoreTmuxBin=$(readlink $tmuxBin)
      nixStoreTmuxBins=$(dirname $nixStoreTmuxBin)
      nixStoreTmux=$(dirname $nixStoreTmuxBins)
      nixStoreTmuxConf="$nixStoreTmux/share/marcuswhybrow-tmux/tmux.conf"
      echo $nixStoreTmuxConf
    '';
    linkConf = pkgs.writeShellScript "link-conf" ''
      mkdir --parents ~/.config/marcuswhybrow-tmux
      ln --symbolic --force $(${getConf}) ~/.config/marcuswhybrow-tmux/tmux.conf
    '';
    wrapper = pkgs.runCommand "tmux-wrapper" {
      nativeBuildInputs = [ pkgs.makeWrapper ];
    } ''
      mkdir --parents $out/bin
      makeWrapper ${pkgs.tmux}/bin/tmux $out/bin/tmux \
        --add-flags "-f $out/share/marcuswhybrow-tmux/tmux.conf"

      mkdir --parents $out/share/marcuswhybrow-tmux
      ln -s ${getConf} $out/share/marcuswhybrow-tmux/get-conf
      ln -s ${linkConf} $out/share/marcuswhybrow-tmux/link-conf

      cat > $out/share/marcuswhybrow-tmux/tmux.conf << EOF
      run-shell ${pkgs.tmuxPlugins.catppuccin.rtp}

      # Conf reloading

      # Tmux sessions are long lived. Changes to tmux.conf are only checked 
      # when a new session is created. I package my tmux conf within a nix 
      # package, meaning there is no shared tmux conf file which is updated.
      # Instead, each update has it's own unique conf file, inaccessible to 
      # all other later versions.
      #
      # The advantage to this is that my tmux conf is portable, I can use it 
      # in remote locations using `nix run github:marcuswhybrow/tmux`. The 
      # downside is that reloading tmux's conf in a long lived session is 
      # difficult. 
      # 
      # To solve this issue, I'm working out the conf file location for that 
      # packaged version of tmux, and linking it to 
      # ~/.config/marcuswhybrow-tmux/tmux.conf. This is bound to the `r` key
      # directly before sourcing that file.
      bind r run-shell "$out/share/marcuswhybrow-tmux/link-conf"\; source-file ~/.config/marcuswhybrow-tmux/tmux.conf

      # During development we can do `nix build` to get a `result` directory,
      # then manually source the conf in the result.
      bind d source-file ./result/share/marcuswhybrow-tmux/tmux.conf

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


      # Catppuccin Theme config

      # set -g @catppuccin_flavour 'mocha'
      set -g @catppuccin_flavour 'latte'
      set -g @catppuccin_window_current_text "#W"
      set -g @catppuccin_window_default_text "#W"

      # I can't get these to work??
      # set -g @catppuccin_status_modules_left ""
      set -g @catppuccin_status_modules_right "host session"
      EOF
    '';
  in {
    packages.x86_64-linux.tmux = pkgs.symlinkJoin {
      name = "tmux";
      paths = [ 
        wrapper # this first ./bin/tmux has precedence
        pkgs.tmux
        pkgs.tmuxPlugins.catppuccin 
      ];
    };

    packages.x86_64-linux.default = inputs.self.packages.x86_64-linux.tmux;
  };
}
