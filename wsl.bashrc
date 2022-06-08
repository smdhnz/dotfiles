# daemon
if test $(service docker status | awk '{print $4}') = 'not'; then #停止状態
    sudo /usr/sbin/service docker start > /dev/null
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

function markup() {
    if [ $# = 0 ]; then
        command echo "invalid args"
    elif [ ! -e $1 ]; then
        command echo "$1 is not found"
    elif [ "$(cd $(dirname $1); pwd)" = "." ]; then
        command docker run -it --init --rm -p 1234:1234 --volume $(pwd):/app/mnt smdhnz/markdown $1
    else
        command docker run -it --init --rm -p 1234:1234 --volume $(cd $(dirname $1); pwd):/app/mnt smdhnz/markdown $1
    fi
}
