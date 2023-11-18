{ dockerCompat, pkgs ? import <pkgs> {} }:

pkgs.mkShell
{
  name = "devops";
  shellHook = ''

    # prompt
    COLOR_RESET="$({ exists tput && tput sgr0; } 2>/dev/null || printf '\033[0m')"
    COLOR_BRED="$({ exists tput && tput bold && tput setaf 1; } 2>/dev/null || printf '\033[1;31m')"
    COLOR_BGREEN="$({ exists tput && tput bold && tput setaf 2; } 2>/dev/null || printf '\033[1;32m')"
    COLOR_BYELLOW="$({ exists tput && tput bold && tput setaf 3; } 2>/dev/null || printf '\033[1;33m')"
    COLOR_BBLUE="$({ exists tput && tput bold && tput setaf 6; } 2>/dev/null || printf '\033[1;34m')"
    COLOR_BCYAN="$({ exists tput && tput bold && tput setaf 6; } 2>/dev/null || printf '\033[1;36m')"
    gitrepo() {
      echo "$(git remote -v 2>/dev/null | grep "(fetch)" | awk -F'\t' '{print $1}')"/"$(git branch 2>/dev/null | grep -e '\* ' | sed 's/^..\(.*\)/\1/')"
    }
    # PS1=$(echo "\n$COLOR_BBLUE\$(git status -s 2> /dev/null)$COLOR_RESET\n $COLOR_BGREEN·$COLOR_RESET$COLOR_BYELLOW aws-shell $COLOR_RESET$COLOR_BRED\$(gitrepo)$COLOR_RESET$COLOR_BCYAN \$(pwd | sed "s:\$\{HOME}:~:g")$COLOR_RESET\n · ")
    PS1=$(echo "\n $COLOR_BGREEN·$COLOR_RESET$COLOR_BYELLOW shell-devops $COLOR_RESET$COLOR_BRED\$(gitrepo)$COLOR_RESET$COLOR_BCYAN \$(pwd | sed "s:\$\{HOME}:~:g")$COLOR_RESET\n · ")

    export REGISTRY_AUTH_FILE=$HOME/.config/containers/policy.json
    mkdir -p $HOME/.config/containers/
    file="$HOME/.config/containers/storage.conf"
    if [ ! -f "$file" ]; then touch "$file"; fi                                                   # creates storage.conf if it doesn't exist
    if ! grep -q "driver = \"overlay\"" "$file"; then                                             # check if "driver overlay" line exists in storage.conf
      if ! grep -q "\[storage\]" "$file"; then echo "[storage]" >> "$file"; fi                    # add storage section if it doesn't exist already
      if grep -q "[storage]" "$file"; then sed -i '/\[storage\]/a driver = "overlay"' "$file"; fi # if the [storage] line exists, add the "driver = overlay" line after it
      rm -rf "$HOME/.local/share/containers/storage/"
    fi
    echo '{
        "default": [
            {
                "type": "insecureAcceptAnything"
            }
        ],
        "transports":
            {
                "docker-daemon":
                    {
                        "": [{"type":"insecureAcceptAnything"}]
                    }
            }
    }' > $HOME/.config/containers/policy.json

    trap "shell closed" EXIT
  '';
  buildInputs = [
    dockerCompat
    pkgs.podman          # Docker compat
    pkgs.podman-compose  # Docker-compose replacement
    pkgs.runc            # Container runtime
    pkgs.conmon          # Container runtime monitor
    pkgs.skopeo          # Interact with container registry
    pkgs.slirp4netns     # User-mode networking for unprivileged namespaces
    pkgs.fuse-overlayfs  # CoW for images, much faster than default vfs
    pkgs.dive            # Exploring layers on docker images
  ];
}
