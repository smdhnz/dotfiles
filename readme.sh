sudo apt update
sudo apt upgrade -y
sudo apt install build-essential unzip xsel ripgrep

# Git
git config --global user.name $YOUR_USER_NAME
git config --global user.email $YOUR_USER_EMAIL
ssh-keygen -t ed25519
cat $HOME/.ssh/id_ed25519.pub # Copy & Save to github

git clone git@github.com:smdhnz/dotfiles.git

cd dotfiles
cat "$PWD/.bashrc" >> "$HOME/.bashrc"

# Volta
curl https://get.volta.sh | bash
volta install node
volta install \
  wsl-open \
  typescript \
  @vtsls/language-server \
  @vue/language-server \
  @fsouza/prettierd \
  @tailwindcss/language-server \
  @google/gemini-cli

# Bun.js
curl -fsSL https://bun.sh/install | bash

# uv
curl -LsSf https://astral.sh/uv/install.sh | bash

# Neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
rm nvim-linux-x86_64.tar.gz
nvim --headless "+Lazy! sync" +qa
nvim --headless -c "TSInstallSync lua json yaml typescript tsx vue dockerfile prisma python" -c "qa"

# Lazygit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
rm -rf lazygit.tar.gz lazygit

# Docker
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && rm get-docker.sh
sudo gpasswd -a $USER docker
sudo service docker restart
