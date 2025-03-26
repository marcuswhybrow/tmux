{
  description = "Tmux terminal multiplexer configured by Marcus";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    fish.url = "github:marcuswhybrow/fish";
  };

  outputs = inputs: let
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    fish = "${inputs.fish.packages.x86_64-linux.fish}/bin/fish";
    tmux = "$out/bin/tmux";
    wrapper = pkgs.runCommand "tmux-wrapper" {
      nativeBuildInputs = [ pkgs.makeWrapper ];
    } ''
      mkdir --parents $out/bin
      makeWrapper ${pkgs.tmux}/bin/tmux $out/bin/tmux \
        --add-flags "source $out/share/marcuswhybrow-tmux/tmux.conf \;"

      mkdir --parents $out/share/marcuswhybrow-tmux

      cat > $out/share/marcuswhybrow-tmux/tmux.conf << EOF
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
      set -g default-terminal "xterm-256color"
      # set-option -ga terminal-features ",xterm-256color:usstyle"
      # set-option -g default-terminal "tmux-256color"
      # set-option -ga terminal-overrides ",alacritty:Tc"
      # set -g default-terminal "alacritty" 
      # set -g terminal-overrides ",alacritty:Tc"

      #set -g default-terminal "alcritty":wq
      # set -as terminal-features ",xterm-256color:RGB"

      # Advice from neovim :checkhealth ("autoread" may not work)
      set-option -g focus-events on

      # Advice from neovim :checkhealth
      set-option -sg escape-time 20

      # # Custom Theme
      set-option -g status-position top
      set -g status-justify centre
      set -g status-left ""
      set -g status-left-length 0
      set -g status-right "#S"
      set -g status-right-length 100

      # setw -g window-status-current-format ' #W '
      # setw -g window-status-format '#W'

      # setw -g window-status-current-format ''
      # setw -g window-status-format ''

      setw -g window-status-current-format '#I #W '
      setw -g window-status-format '#I #W '

      set -g status-left-style 'fg=cyan bg=default'
      set -g status-right-style 'fg=default bg=default'
      setw -g window-status-current-style 'fg=cyan bg=default'
      setw -g window-status-style 'fg=default  bg=default'
      set -g status-style fg=default,bg=default
      set -g status-bg "default"
      set -g message-style 'fg=default bg=default'
      setw -g window-status-bell-style 'fg=red bg=default'

      # Make windows start from 1 (not 0)
      set -g base-index 1
      setw -g pane-base-index 1

      bind-key 1 if-shell '${tmux} select-window -t :1' ''' 'new-window -t :1'
      bind-key 2 if-shell '${tmux} select-window -t :2' ''' 'new-window -t :2'
      bind-key 3 if-shell '${tmux} select-window -t :3' ''' 'new-window -t :3'
      bind-key 4 if-shell '${tmux} select-window -t :4' ''' 'new-window -t :4'
      bind-key 5 if-shell '${tmux} select-window -t :5' ''' 'new-window -t :5'
      bind-key 6 if-shell '${tmux} select-window -t :6' ''' 'new-window -t :6'
      bind-key 7 if-shell '${tmux} select-window -t :7' ''' 'new-window -t :7'
      bind-key 8 if-shell '${tmux} select-window -t :9' ''' 'new-window -t :9'
      bind-key 0 if-shell '${tmux} select-window -t :10' ''' 'new-window -t :10'
      
      EOF
    '';

    fishAbbrs = pkgs.writeTextDir "share/fish/vendor_conf.d/marcuswhybrow-tmux.fish" ''
      if status is-interactive
        abbr --add n tmux new -A -s nixos ~/Repos/nixos
        abbr --add c tmux new -A -s config ~/.config
      end
    '';

    fishFuncs = pkgs.symlinkJoin {
      name = "tmux-fish-funcs";
      paths = [
        (pkgs.writeTextDir "share/fish/vendor_functions.d/code.fish" ''
          function code 
            set name (ls $HOME/Repos | ${pkgs.fzf}/bin/fzf --bind tab:up,btab:down)
            tmux new \
              -A \
              -s "$name" \
              -c "$HOME/Repos/$name"
          end
        '')
      ];
    };
  in {
    packages.x86_64-linux.tmux = pkgs.symlinkJoin {
      name = "tmux";
      paths = [ 
        wrapper # this first ./bin/tmux has precedence
        pkgs.tmux
        fishAbbrs
        fishFuncs
      ];
    };

    packages.x86_64-linux.default = inputs.self.packages.x86_64-linux.tmux;
  };
}
