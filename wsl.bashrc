# daemon
if test $(service docker status | awk '{print $4}') = 'not'; then #停止状態
    sudo /usr/sbin/service docker start > /dev/null
fi
if test $(service ssh status | awk '{print $4}') = 'not'; then #停止状態
    sudo /usr/sbin/service ssh start > /dev/null
fi
# alias
alias open='wsl-open'
alias python='python3'
alias dockernone='docker rmi `docker images | grep none | grep -oE "[a-zA-Z0-9]{12}" | xargs`'
alias hostip='echo `ipconfig.exe | grep IPv4 | grep -oE "192\.168\.[0-9]*\.[0-9]*"`'
alias activate='source .venv/bin/activate'
alias tree='tree -N'
alias ec2='ssh -i $HOME/.ssh/aws_ec2_key_pair.pem ec2-user@ec2-54-250-250-101.ap-northeast-1.compute.amazonaws.com'
alias dc-purge='docker-compose down --rmi all --volumes --remove-orphans'
alias dc='docker-compose'
alias sudocker='docker run -it --rm --privileged --pid=host justincormack/nsenter1'
alias vim='nvim'
alias vimrc='nvim ~/.config/nvim/init.vim'
alias bashrc='nvim ~/.bashrc'
alias t='tb'
alias wtsetting='vim /mnt/c/Users/kato-f.ETIC-TOKYO/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json'
alias rm='mv --backup=numbered --target-directory=$HOME/.trash'

export GHKEY=""
export PATH="$HOME/.yarn/bin:$PATH"
