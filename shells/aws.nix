{ dockerCompat, pkgs ? import <pkgs> {} }:

pkgs.mkShell
{
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
    PS1=$(echo "\n $COLOR_BGREEN·$COLOR_RESET$COLOR_BYELLOW shell-aws $COLOR_RESET$COLOR_BRED\$(gitrepo)$COLOR_RESET$COLOR_BCYAN \$(pwd | sed "s:\$\{HOME}:~:g")$COLOR_RESET\n · ")

    export REGISTRY_AUTH_FILE=$HOME/.config/containers/policy.json
    mkdir -p $HOME/.config/containers/
    file="$HOME/.config/containers/storage.conf"
    if [ ! -f "$file" ]; then touch "$file"; fi                                                   # creates storage.conf if it doesn't exist
    if ! grep -q "driver = \"overlay\"" "$file"; then                                             # check if "driver overlay" line exists in storage.conf
      if ! grep -q "\[storage\]" "$file"; then echo "[storage]" >> "$file"; fi                    # add storage section if it doesn't exist already
      if grep -q "[storage]" "$file"; then sed -i '/\[storage\]/a driver = "overlay"' "$file"; fi # if the [storage] line exists, add the "driver = overlay" line after it
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

    if [ ! -f "$HOME/.aws/credentials" ]; then
      aws configure
      read -p "Do you want to configure an AWS registry? [y/n]: " bool
      echo ""
      if [ $bool = "y" ]; then
        read -p 'aws region:' awsregion
        read -p 'aws container registry:' awscontainerregistry
        echo "awsregion $awsregion\n" > $HOME/.aws/login
        echo "awscontainerregistry $awscontainerregistry" >> $HOME/.aws/login
      fi
    fi
    alias loginaws="aws ecr get-login-password --region \$(cat \$HOME/.aws/login | grep awsregion | awk -F' ' '{printf \$NF}' | tr -d '\n') | docker login --username AWS --password-stdin \$(cat \$HOME/.aws/login | grep awscontainerregistry | awk -F' ' '{printf \$NF}')"

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
    pkgs.awscli2         # Manage AWS services
  ];
}
