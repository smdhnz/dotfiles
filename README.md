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

`link-dotfiles.sh`はいつでも再実行できる。リポジトリの移動・ディレクトリ名変更後や、リンクの修復、設定の再反映に使用する。

```bash
./link-dotfiles.sh
```

Piの`settings.json`は既存設定へマージし、同じ項目はリポジトリ側の値で更新する。

## 更新

```bash
cd ~/dotfiles
mise upgrade
mise lock
./install-bun-tools.sh
sudo apt-get update && sudo apt-get upgrade
```
