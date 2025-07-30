#!/bin/bash

# setup.sh - Symlink dotfiles to home directory (excluding .bashrc)

echo "Setting up dotfiles..."

# Symlink .config/nvim/init.lua
if [ -f "$PWD/.config/nvim/init.lua" ]; then
    if [ -e ~/.config/nvim/init.lua ]; then
        cp ~/.config/nvim/init.lua ~/.config/nvim/init.lua.backup.$(date +%Y%m%d_%H%M%S)
        echo "Backed up ~/.config/nvim/init.lua to ~/.config/nvim/init.lua.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    mkdir -p ~/.config/nvim
    ln -sf "$PWD/.config/nvim/init.lua" ~/.config/nvim/init.lua
    echo "Symlinked .config/nvim/init.lua"
fi

# Symlink .gemini/settings.json
if [ -f "$PWD/.gemini/settings.json" ]; then
    if [ -e ~/.gemini/settings.json ]; then
        cp ~/.gemini/settings.json ~/.gemini/settings.json.backup.$(date +%Y%m%d_%H%M%S)
        echo "Backed up ~/.gemini/settings.json to ~/.gemini/settings.json.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    mkdir -p ~/.gemini
    ln -sf "$PWD/.gemini/settings.json" ~/.gemini/settings.json
    echo "Symlinked .gemini/settings.json"
fi

# Symlink .qwen/settings.json
if [ -f "$PWD/.qwen/settings.json" ]; then
    mkdir -p ~/.qwen
    ln -sf "$PWD/.qwen/settings.json" ~/.qwen/settings.json
    echo "Symlinked .qwen/settings.json"
fi

echo "Setup complete!"
