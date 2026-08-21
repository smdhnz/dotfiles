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
git clone <repository-url> ~/dotfiles
cd ~/dotfiles
./install.sh
```

`.pi/agent/settings.json`は既存設定とのマージが必要なため自動配置しない。

```bash
jq -s '.[0] * .[1]' ~/.pi/agent/settings.json ~/dotfiles/.pi/agent/settings.json \
  > /tmp/pi-settings.json && mv /tmp/pi-settings.json ~/.pi/agent/settings.json
```

## Devboxからの移行

削除は必ずmise環境の検証後に行う。旧リポジトリ`~/.devbox`全体を先に削除しない。

1. `~/dotfiles/install.sh`を実行する。
2. 新しいbashでmise管理ツールとPi/VS Codeからの実行を確認する。
3. `~/.profile`から`cd ~/.devbox && devbox shell`を削除する。
4. Devbox本体・キャッシュ・プロジェクト生成物を削除する。
5. `/nix/nix-installer uninstall`でNixを削除する。

現在の環境はDeterminate Nix Installerによるmulti-user構成なので、Nix削除には次を使用する。

```bash
sudo /nix/nix-installer uninstall
```

Devbox削除対象:

```bash
sudo rm -f /usr/local/bin/devbox
rm -rf ~/.cache/devbox ~/.local/share/devbox ~/.devbox/.devbox
```

Nixアンインストール後、`/nix`、`~/.nix-*`、`~/.local/state/nix`、`nixbld`ユーザー／グループ、systemd unit、`/etc/profile.d/nix.sh`が残っていないことを個別に確認する。確認前に手動削除しない。

## 更新

```bash
cd ~/dotfiles
mise upgrade
mise lock
./install-bun-tools.sh
sudo apt-get update && sudo apt-get upgrade
```
