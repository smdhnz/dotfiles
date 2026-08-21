# dotfiles

Ubuntu/WSL向けの開発環境。OS依存はapt、言語ランタイムと更新頻度の高いCLIはmise、Node製CLIはbunで管理する。

## 管理範囲

- `packages.apt`: ネイティブライブラリ、ビルド基盤、OS統合ツール
- `mise.toml`: Node、Bun、uv、Neovim、Git/AWS/GCP系CLI
- `install-bun-tools.sh`: Pi、language server等のNode製グローバルCLI
- `shell_setup.sh`: 軽量な環境変数、mise activation、alias、function
- `.config/`, `.pi/`: dotfiles本体

シェル起動時にインストールや更新は行わない。非対話プロセス向けにmise shimsを常時`PATH`へ追加する。

## 新規セットアップ

```bash
git clone https://github.com/smdhnz/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

`.pi/agent/settings.json`は既存設定とのマージが必要なため自動配置しない。

```bash
jq -s '.[0] * .[1]' ~/.pi/agent/settings.json ~/dotfiles/.pi/agent/settings.json \
  > /tmp/pi-settings.json && mv /tmp/pi-settings.json ~/.pi/agent/settings.json
```

## 更新

```bash
cd ~/dotfiles
mise upgrade
mise lock
./install-bun-tools.sh
sudo apt-get update && sudo apt-get upgrade
```
