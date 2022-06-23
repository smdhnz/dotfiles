# First Setup

```bash
$ sudo apt update && sudo apt upgrade
$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
$ echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/$(whoami)/.profile
$ eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
$ sudo apt-get install build-essential
$ brew install gcc
$ brew install python@3.10
$ echo 'export PATH="/home/linuxbrew/.linuxbrew/opt/python@3.10/bin:$PATH"' >> ~/.profile
$ echo 'export LDFLAGS="-L/home/linuxbrew/.linuxbrew/opt/python@3.10/lib"' >> ~/.profile
$ echo 'export CPPFLAGS="-I/home/linuxbrew/.linuxbrew/opt/python@3.10/include"' >> ~/.profile
$ brew install n
$ sudo /home/linuxbrew/.linuxbrew/bin/n lts
$ sudo npm --location=global install yarn
$ echo 'export PATH="/home/$(whoami)/.yarn/bin:$PATH"' >> ~/.profile
$ yarn global add wsl-open
$ sudo apt-get remove docker docker-engine docker.io containerd runc
$ sudo apt-get install ca-certificates curl gnupg lsb-release
$ sudo mkdir -p /etc/apt/keyrings
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
$ echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
$ sudo apt-get update
$ sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
$ sudo visudo
> [username] ALL=(ALL:ALL) NOPASSWD: /usr/sbin/service docker start
$ echo "if test $(service docker status | awk '{print $4}') = 'not'; then
    sudo /usr/sbin/service docker start
  fi" >> ~/.bashrc
$ sudo curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
$ sudo chmod +x /usr/local/bin/docker-compose
$ brew install --HEAD luajit
$ brew install --HEAD neovim
$ curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

## vim ts server install
https://github.com/nvim-treesitter/nvim-treesitter
```
:TSInstall <language>
```

## nerd font ( windows terminal )
download: https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/CascadiaCode.zip

## coc-explorer
```
:CocInstall coc-explorer
:CocConfig
```
