{
  description = "Tmux terminal multiplexer configured by Marcus";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    fish.url = "github:marcuswhybrow/fish";
    neovim.url = "github:marcuswhybrow/neovim";
  };

  outputs = inputs: let
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    fish = "${inputs.fish.packages.x86_64-linux.fish}/bin/fish";
    vim = "${inputs.neovim.packages.x86_64-linux.nvim}/bin/vim";
    gitmux = "${pkgs.gitmux}/bin/gitmux";
    tmux = "$out/bin/tmux";
    wrapper = pkgs.runCommand "tmux-wrapper" {
      nativeBuildInputs = [ pkgs.makeWrapper ];
    } ''
      mkdir --parents $out/bin
      makeWrapper ${pkgs.tmux}/bin/tmux $out/bin/tmux \
        --add-flags "source $out/share/marcuswhybrow-tmux/tmux.conf \;"

      mkdir --parents $out/share/marcuswhybrow-tmux

      cat > $out/share/marcuswhybrow-tmux/gitmux.conf << EOF
        tmux:
          symbols:
              branch: '''
              hashprefix: ':'
              ahead: ↑
              behind: ↓
              staged: ''
              conflict: ''
              modified: '+'
              untracked: '…'
              stashed: '⚑'
              clean: 
              insertions: Σ
              deletions: Δ
          styles:
              clear: '#[fg=brightblack]'
              state: '#[fg=brightblack]'
              branch: '#[fg=brightblack]'
              remote: '#[fg=brightblack]'
              divergence: '#[fg=brightblack]'
              staged: '#[fg=brightblack]'
              conflict: '#[fg=brightblack]'
              modified: '#[fg=brightblack]'
              untracked: '#[fg=brightblack]'
              stashed: '#[fg=brightblack]'
              clean: '#[fg=brightblack]'
              insertions: '#[fg=brightblack]'
              deletions: '#[fg=brightblack]'
          layout: [divergence, flags, branch, ' ']
          options:
              branch_max_len: 0
              branch_trim: right
              ellipsis: …
              hide_clean: true
              swap_divergence: false
              divergence_space: false
      EOF

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

      # Tmux position
      set-option -g status-position top

      # Status format
      set -g status-justify centre
      set -g status-style 'fg=default bg=default'
      set -g message-style 'fg=default bg=default'

      # Left aligned area
      set -g status-left ""
      set -g status-left-length 100
      set -g status-left-style 'fg=brightblack bg=default'

      # Window current
      setw -g window-status-current-format '#I #W '
      setw -g window-status-current-style 'fg=default bg=default'

      # Window normal
      setw -g window-status-format '#I #W '
      setw -g window-status-style 'fg=brightblack bg=default'

      # Window bell
      setw -g window-status-bell-style 'fg=red bg=default'

      # Right aligned area
      set -g status-right '#(${gitmux} -cfg $out/share/marcuswhybrow-tmux/gitmux.conf "#{pane_current_path}")#S'
      set -g status-right-length 100
      set -g status-right-style 'fg=brightblack bg=default'

      # Pane borders
      set -g pane-active-border-style 'fg=brightblack bg=default'
      set -g pane-border-style 'fg=brightblack bg=default'

      # Make windows start from 1 (not 0)
      set -g base-index 1
      setw -g pane-base-index 1

      # Create or select windows
      bind-key 1 if-shell '${tmux} select-window -t :1' ''' 'new-window -t :1'
      bind-key 2 if-shell '${tmux} select-window -t :2' ''' 'new-window -t :2'
      bind-key 3 if-shell '${tmux} select-window -t :3' ''' 'new-window -t :3'
      bind-key 4 if-shell '${tmux} select-window -t :4' ''' 'new-window -t :4'
      bind-key 5 if-shell '${tmux} select-window -t :5' ''' 'new-window -t :5'
      bind-key 6 if-shell '${tmux} select-window -t :6' ''' 'new-window -t :6'
      bind-key 7 if-shell '${tmux} select-window -t :7' ''' 'new-window -t :7'
      bind-key 8 if-shell '${tmux} select-window -t :9' ''' 'new-window -t :9'
      bind-key 0 if-shell '${tmux} select-window -t :10' ''' 'new-window -t :10'

      bind-key c run-shell "fish --command code"

      bind-key !   if-shell '${tmux} select-window -t :1'  'swap-window -dt :1'  'move-window -t :1'
      bind-key '"' if-shell '${tmux} select-window -t :2'  'swap-window -dt :2'  'move-window -t :2'
      bind-key £   if-shell '${tmux} select-window -t :3'  'swap-window -dt :3'  'move-window -t :3'
      bind-key $   if-shell '${tmux} select-window -t :4'  'swap-window -dt :4'  'move-window -t :4'
      bind-key %   if-shell '${tmux} select-window -t :5'  'swap-window -dt :5'  'move-window -t :5'
      bind-key ^   if-shell '${tmux} select-window -t :6'  'swap-window -dt :6'  'move-window -t :6'
      bind-key &   if-shell '${tmux} select-window -t :7'  'swap-window -dt :7'  'move-window -t :7'
      bind-key *   if-shell '${tmux} select-window -t :8'  'swap-window -dt :8'  'move-window -t :8'
      bind-key (   if-shell '${tmux} select-window -t :9'  'swap-window -dt :9'  'move-window -t :9'
      bind-key )   if-shell '${tmux} select-window -t :10' 'swap-window -dt :10' 'move-window -t :10'
      
      EOF
    '';

    fishAbbrs = pkgs.writeTextDir "share/fish/vendor_conf.d/marcuswhybrow-tmux.fish" /* fish */ ''
      if status is-interactive
        abbr --add n tmux new -A -s nixos ~/Repos/nixos
        abbr --add c tmux new -A -s config ~/.config
      end
    '';

    fishFuncs = pkgs.symlinkJoin {
      name = "tmux-fish-funcs";
      paths = [
        (pkgs.writeTextDir "share/fish/vendor_completions.d/code.fish" /* fish */ ''
          complete \
            --command code \
            --no-files \
            --arguments "(complete-code)"
        '')
        (pkgs.writeTextDir "share/fish/vendor_functions.d/complete-code.fish" /* fish */ ''
          function complete-code 
            set sessions "$(tmux list-sessions | sed -E 's/:.*$//')"
            for name in (ls $HOME/Repos)
              if echo $sessions | grep --line-regexp "$name" >/dev/null
                echo -e "$name\tactive"
              else
                echo -e "$name\t"
              end
            end
          end
        '')
        (pkgs.writeTextDir "share/fish/vendor_functions.d/code.fish" /* fish */ ''
          function code 
            set base "$HOME/Repos"
            set name "$argv[1]"
            
            if test -z "$name" || not test -d "$base/$name"
            set name (ls "$base" | ${pkgs.fzf}/bin/fzf \
              --select-1 \
              --border  \
              --height 20 \
              --reverse \
              --bind tab:down,btab:up \
              --tmux 90%,60% \
              --query "$name" \
              --preview "ls $base/{}" \
            )
            end

            if not test -d "$base/$name"
              echo "There's no repo named '$name'"
              exit 1
            end

            set dir "$HOME/Repos/$name"

            if not tmux has-session -t "$name"
              tmux new -ds "$name" -c "$dir"
              tmux send-keys -t "$name.1" "${vim} ." ENTER
            end

            if test -n "$TMUX"
              tmux switch-client -t "$name"
            else
              tmux attach -t "$name"
            end
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
