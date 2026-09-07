# dotfiles

Ubuntu/WSL向けの開発環境。OS依存はapt、言語ランタイムと更新頻度の高いCLIはmise、Node製CLIはbunで管理する。

## 管理範囲

- `packages.apt`: ネイティブライブラリ、ビルド基盤、OS統合ツール
- `mise.toml`: Node、Bun、uv、Neovim、Git/AWS/GCP系CLI
- `install-bun-tools.sh`: OMP、Pi、language server等のNode製グローバルCLI
- `shell_setup.sh`: 軽量な環境変数、mise activation、alias、function
- `.config/`, `.omp/`, `.pi/`: dotfiles本体

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

OMPのグローバル指示と`config.yml`は`~/.omp/agent/`へリンクする。認証情報、セッション、キャッシュはOMP自身の管理対象として置換しない。画像生成はOMP内蔵ツールを有効化し、Codex認証を優先して使用する。

Piのグローバル指示と`settings.json`は`~/.pi/agent/`へリンクする。指示は`.pi/agent/AGENTS.md`からOMPの`AGENTS.md`を参照して共有する。現在の設定はOpenAI Codexの`gpt-6-astra`、darkテーマ、出力・入力欄の横余白0。OMP固有のUI・ツール設定は移植しない。

Piの認証情報（`auth.json`）、セッション、モデルカタログ、信頼情報などの実行時データは管理・置換しない。`lastChangelogVersion`は初期設定に含めない（Piが後から書き込む場合がある）。`/settings`等で保存した変更はリンク先のdotfilesにも反映される。リンク時は既存設定ファイルを置換するため、必要なら事前にバックアップする。

### GitHub SSH認証

SSH鍵を作成し、表示された公開鍵を[GitHub Settings > SSH and GPG keys](https://github.com/settings/keys)の「New SSH key」から登録する。既存の`~/.ssh/id_ed25519`がある場合は上書きせず、その公開鍵を使用する。

```bash
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```

`-N ""`はパスフレーズなしで鍵を作成する指定。パスフレーズを設定する場合は省略する。

このリポジトリもSSHで接続する場合は、リモートURLを変更する。

```bash
git remote set-url origin git@github.com:smdhnz/dotfiles.git
```

### Docker

Docker Engineをインストールし、現在のユーザーを`docker`グループに追加する。

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker "$USER"
```

`docker`グループにはroot相当の権限が付与される。グループ変更の反映には再ログインが必要。WSLではWindows側のPowerShellで次を実行し、Ubuntuを開き直す（すべてのWSLディストリビューションが停止する）。

```powershell
wsl --shutdown
```

## 更新

```bash
cd ~/dotfiles
mise upgrade
mise lock
./install-bun-tools.sh
sudo apt-get update && sudo apt-get upgrade
```
