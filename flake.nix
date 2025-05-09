{
  description = "Tmux terminal multiplexer configured by Marcus";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    marcus-fish.url = "github:marcuswhybrow/fish";
  };

  outputs = inputs: let
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    marcus-fish = "${inputs.marcus-fish.packages.x86_64-linux.fish}/bin/fish";
    gitmux = "${pkgs.gitmux}/bin/gitmux";
    tmux = "$out/bin/tmux";
    wrapper = pkgs.runCommand "tmux-wrapper" {
      nativeBuildInputs = [ pkgs.makeWrapper ];
    } ''
      mkdir --parents $out/bin

      # Typically I replace the original executable with a script which passes 
      # through all arguments to the orignal, save adding in the pertenant 
      # config flag for that executable with a path to my custom config.
      #
      # This works for tmux only on the first invocation. On the first 
      # invocation tmux starts itself as a server, and indeed honours the 
      # config file passed in using the -f flag.
      # 
      # Subsequent invocations ignore the -f flag since the server is already 
      # running. Tmux offers the `source` command for forcing the server to 
      # source a new conf file. However we can't simply prefix this to every 
      # command as it only works in conjuction with a subset of tmux commands.
      #
      # By running `tmux source` as a separate command before every invocation 
      # we bypass this issue altogether. `tmux source` will fail if the server 
      # is not running so we use `|| true` to ignore that case, and `&>/dev/null`
      # to supress all output.
      
      makeWrapper ${pkgs.tmux}/bin/tmux $out/bin/tmux \
        --run "${pkgs.tmux}/bin/tmux source $out/share/marcuswhybrow-tmux/tmux.conf &>/dev/null || true" \
        --add-flags "-f $out/share/marcuswhybrow-tmux/tmux.conf"

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
              clear: '#[fg=brightblack,nobold]'
              state: '#[fg=brightblack]'
              branch: '#[fg=brightblack]'
              remote: '#[fg=brightblack]'
              divergence: '#[fg=terminal,bold]'
              staged: '#[fg=brightblack]'
              conflict: '#[fg=brightblack]'
              modified: '#[fg=brightblack]'
              untracked: '#[fg=brightblack]'
              stashed: '#[fg=brightblack]'
              clean: '#[fg=brightblack]'
              insertions: '#[fg=brightblack]'
              deletions: '#[fg=brightblack]'
          layout: [divergence, flags, branch]
          options:
              branch_max_len: 0
              branch_trim: right
              ellipsis: …
              hide_clean: true
              swap_divergence: false
              divergence_space: false
      EOF

      #run-shell ${pkgs.tmuxPlugins.vim-tmux-navigator.rtp}
      cat > $out/share/marcuswhybrow-tmux/tmux.conf << EOF

      set -g default-command "${marcus-fish}"

      set -g prefix C-space
      unbind C-b
      bind C-space send-prefix

      # Set terminal history large enough to view multiple long stack traces
      set-option -g history-limit 10000

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

      # Status refresh frequency in seconds
      set -g status-interval 5

      # Tmux position
      set-option -g status-position top

      # Status format
      set -g status-justify centre
      set -g status-style 'fg=default bg=default'
      set -g message-style 'fg=default bg=default'

      # Left aligned area
      # set -g status-left "#S"
      set -g status-left-length 100
      # set -g status-left-style 'fg=brightblack bg=default'

      set -g status-left '#(tmux-status-left)'
      # set -g status-left-style '#(tmux_left_status_color)'

      # Window current
      setw -g window-status-current-format '#I #W '
      setw -g window-status-current-style 'fg=default,bold bg=default'

      # Window normal
      setw -g window-status-format '#I #W '
      setw -g window-status-style 'fg=brightblack bg=default'

      # Window bell
      setw -g window-status-bell-style 'fg=red bg=default'

      # Right aligned area
      set -g status-right '#(${gitmux} -cfg $out/share/marcuswhybrow-tmux/gitmux.conf "#{pane_current_path}")'
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

      bind-key L 'switch-client -l; refresh-client -S'

      # Navigate vim and tmux splits with <C-h/j/k/l> keymaps
      # - https://github.com/christoomey/vim-tmux-navigator

      is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"
      bind-key -n C-h if-shell "\$is_vim" 'send-keys C-h'  'select-pane -L'
      bind-key -n C-j if-shell "\$is_vim" 'send-keys C-j'  'select-pane -D'
      bind-key -n C-k if-shell "\$is_vim" 'send-keys C-k'  'select-pane -U'
      bind-key -n C-l if-shell "\$is_vim" 'send-keys C-l'  'select-pane -R'
      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R

      bind-key -n MouseDown1StatusLeft run-shell 'fish --command code'

      bind-key -r C-r run-shell 'colour red'
      bind-key -r C-g run-shell 'colour green'
      bind-key -r C-b run-shell 'colour blue'
      bind-key -r C-d run-shell 'colour'
      
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
        # This code is located such that fish will automatically call it.
        # It sets up the correct automatic tab completion values for the 
        # fish `code` function define below.
        (pkgs.writeTextDir "share/fish/vendor_completions.d/code.fish" /* fish */ ''
          complete \
            --command code \
            --no-files \
            --arguments "(complete-code)"
        '')

        # This is a helper function for automatic tab completion of the `code` fish function.
        # It's output conforms to fish completion format:
        # - https://fishshell.com/docs/current/completions.html
        #
        # Each line has two fields separated by a TAB character.
        # Field 1 is a value which may be selected
        # Field 2 is it's description
        #
        # In this case, ehe description will show "active" if there's an active 
        # tmux session of that name
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

        # Utility function to start or switch to tmux sessions named after any project 
        # in the ~/Repos directory.
        (pkgs.writeTextDir "share/fish/vendor_functions.d/code.fish" /* fish */ ''
          function code 
            set base "$HOME/Repos"
            set name "$argv[1]"
            set sessions "$(tmux list-sessions | sed -E 's/:.*$//')"

            # First arg does NOT match any dir in ~/Repos
            if test -z "$name" || not test -d "$base/$name"
              set repos (ls "$base")

              # Calc length of longest dir name in ~/Repos
              set max_length 0
              for repo in $repos
                set len (string length "$repo")
                if test $len -gt $max_length 
                  set max_length $len
                end
              end

              # fzf can split lines into "fields" given a "delimiter".
              # We'll create two fields, the first preserving the exact dir name,
              # the second being what we want the user to see. e.g.
              #
              #       repo_a/repo_a       (active)
              # repository_b/repository_b (active)
              #      another/another
              #
              # I aligned it by the delimiter only for legibility.
              #
              # The delimiter MUST be "/" as it's the only character NOT allowed 
              # in a directory name.
              set fzf_items "$(
                for repo in $repos
                  set len (string length "$repo")
                  set delta (math $max_length - $len)
                  set margin 1
                  set padding_count (math $delta + $margin)
                  set padding (string repeat -n $padding_count ' ')

                  if echo $sessions | grep --line-regexp "$repo" >/dev/null
                    echo -e "$repo/$repo$padding(active)"
                  else
                    echo -e "$repo/$repo$padding"
                  end
                end 
              )"


              # Here we ask fzf (a visual fuzzy finder) to show the user the
              # above items. It will show the second field to the user, whilst
              # using the preserved path (the first field) for it's preview.
              set fzf_choice "$(echo "$fzf_items" | ${pkgs.fzf}/bin/fzf \
                --preview-label "Preview" \
                --delimiter "/" \
                --with-nth 2 \
                --highlight-line \
                --select-1 \
                --border  \
                --info hidden \
                --height 20 \
                --reverse \
                --bind tab:down,btab:up \
                --tmux 90%,60% \
                --query "$name" \
                --preview "ls $base/{1}" \
              )"

              # fzf returns the full item (both fields), but we only need the 
              # orginal repo directory name (the first field)
              set name (echo "$fzf_choice" | cut --delimiter "/" --fields 1)
            end

            if test -z "$name"
              # Do nothing
            else if not test -d "$base/$name"
              echo "There's no repo named '$name'"
            else 
              set dir "$HOME/Repos/$name"

              if not tmux has-session -t "$name"
                tmux new -ds "$name" -c "$dir"
                tmux send-keys -t "$name.1" "$EDITOR ." ENTER
              end


              # If already inside a tmux session, one cannot "attach" to another
              # session. One must instead "switch-client"
              if test -n "$TMUX"
                tmux switch-client -t "$name"
              else
                tmux attach -t "$name"
              end

              # Immediately refresh the status line 
              # normally takes a number of seconds defined by `status-interval`
              tmux refresh-client -S
            end
          end
        '')

        (pkgs.writeShellScriptBin "tmux-status-left" /* sh */ ''
          config_base=''${XDG_CONFIG_HOME:-''$HOME/.config}
          config="''$config_base/tmux-status-left"
          session_name=''$(tmux display-message -p '#S')
          if [ -f "''$config/''$session_name" ]; then
            cat "''$config/''$session_name"
          else 
            echo "#S"
          fi
          '')

        (pkgs.writeShellScriptBin "colour" /* sh */ ''
          config_base=''${XDG_CONFIG_HOME:-''$HOME/.config}
          config="''$config_base/tmux-status-left"
          session_name=''$(tmux display-message -p '#S')
          file="$config/$session_name"

          if [ -z "$1" ]; then 
            echo "#S" > "$file"
            tmux refresh-client -S
            exit 0
          elif [[ "$1" == "orange" ]]; then 
            fg="#441306"; bg="#ff6900"
          elif [[ "$1" == "red" ]]; then 
            fg="#460809"; bg="#fb2c36"
          elif [[ "$1" == "purple" ]]; then 
            fg="#3c0366"; bg="#ad46ff"
          elif [[ "$1" == "pink" ]]; then 
            fg="#510424"; bg="#f6339a"
          elif [[ "$1" == "green" ]]; then 
            fg="#032e15"; bg="#00c950"
          elif [[ "$1" == "lime" ]]; then 
            fg="#192e03"; bg="#7ccf00"
          elif [[ "$1" == "yellow" ]]; then 
            fg="#432004"; bg="#f0b100"
          elif [[ "$1" == "sky" ]]; then 
            fg="#052f4a"; bg="#00a6f4"
          elif [[ "$1" == "blue" ]]; then 
            fg="#162456"; bg="#2b7fff"
          elif [[ "$1" == "slate" ]]; then 
            fg="#020618"; bg="#62748e"
          elif [[ "$1" == "neutral" ]]; then 
            fg="#0a0a0a"; bg="#737373"
          fi
          
          echo "#[fg=''$fg bg=''$bg bold range=left]  #S  " > "''$config/''$session_name"
          tmux refresh-client -S
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
