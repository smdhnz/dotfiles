mkdir -p $HOME/.gemini
ln -sf "$PWD/gemini-cli.json" $HOME/.gemini/settings.json

mkdir -p $HOME/.config/crush
ln -sf "$PWD/crush.json" $HOME/.config/crush/crush.json

mkdir -p $HOME/.local/bin
ln -sf "$PWD/cr" $HOME/.local/bin/cr

mkdir -p $HOME/.config/nvim
ln -sf "$PWD/init.lua" $HOME/.config/nvim/init.lua
