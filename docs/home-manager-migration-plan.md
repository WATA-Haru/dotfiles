# Home Manager 移行計画

実習手順：

1. [`home-manager-first-step.md`](./home-manager-first-step.md): 最小構成のbuildとactivate
2. [`home-manager-step2-zsh.md`](./home-manager-step2-zsh.md): 既存bashを残したzshの導入と検証
3. [`home-manager-step3-login-shell.md`](./home-manager-step3-login-shell.md): NixOSでzshをログインシェルに設定
4. [`home-manager-step4-shell-essentials.md`](./home-manager-step4-shell-essentials.md): bashから必要な設定と依存CLIをzsh環境へ移行
5. [`home-manager-step5-neovim.md`](./home-manager-step5-neovim.md): Lua設定を維持したままNeovimをHome Managerへ移行
6. [`home-manager-step6-neovim-lsp.md`](./home-manager-step6-neovim-lsp.md): NeovimのLSPをmiseの絶対パスからNixへ移行
7. [`home-manager-step7-retire-mise.md`](./home-manager-step7-retire-mise.md): 旧mise設定を解体し、常用CLIをHome Managerへ移行
8. [`home-manager-step8-tmux.md`](./home-manager-step8-tmux.md): host共通構成を分離し、tmuxをHome Managerへ移行
9. [`home-manager-step9-git.md`](./home-manager-step9-git.md): Git本体と一般設定をHome Managerへ移し、identityをローカルファイルへ分離
10. [`home-manager-step10-ghq-retire-chezmoi.md`](./home-manager-step10-ghq-retire-chezmoi.md): ghq workflowを確定し、chezmoiを通常運用から撤去

## 目的

このリポジトリの dotfiles と開発用 CLI 環境を、chezmoi と個別のインストールスクリプトから Nix + Home Manager へ段階的に移行する。

目標は OS 全体の完全再現ではない。新しい端末で Nix を導入し、対象ホストの Home Manager 構成を適用すれば、普段使う開発環境が再現される状態を目指す。

この計画は [`02_Ideas/build-my-dotfiles.md`](../../../02_Ideas/build-my-dotfiles.md) の構想も取り込む。移行そのものと、移行後に育てる開発環境の機能追加を分け、途中でも日常利用できる状態を保つ。

## 現在の最優先課題

現在の `.bashrc` はmiseとble.shを無条件に読み込むため、未導入のNixOS環境や`nix-shell`で次のようにshell起動が壊れる。

```text
bash: /home/hwata/.local/bin/mise: No such file or directory
bash: /home/hwata/.local/share/blesh/ble.sh: No such file or directory
```

最初のマイルストーンは「完成したdotfiles」ではなく、次を満たす最小環境とする。

- 新しいshellがエラーなく起動する
- Home Managerがzsh、Git、tmux、Neovim、fzf、ghq、jujutsuを導入できる
- オプションの外部ツールがなくてもshell起動を妨げない
- NixOS minimalへSSHし、tmuxとNeovimを利用できる

既存のbash + ble.sh構成は延命せず、zshへ移行する。既存 `.bashrc` からはalias、関数、環境変数など必要な設定だけを回収し、Ubuntu標準の雛形やble.sh初期化は移植しない。

## 管理境界

### Home Manager で管理するもの

- zsh、Git、tmux、Neovim の設定
- Ghostty、mise、fcitx5 などのユーザー設定
- ripgrep、fd、fzf、jq、Neovim など、普段どの端末でも利用する CLI
- LSP、formatter、linter など、ユーザー環境に常設する開発支援ツール
- 環境変数、alias、ユーザー単位の設定ファイル
- Ubuntu、NixOS、macOS 間で共有できる設定

### OS または別の仕組みに任せるもの

- Ubuntu の GUI、GNOME、ドライバ、IME の導入、Bluetooth、オーディオ
- Docker daemon などの system service
- ブラウザ、Slack、Obsidian など、OS と統合して利用する GUI アプリ
- macOS の Dock、Finder、セキュリティ設定、MDM 管理対象
- NixOS の system configuration
- プロジェクト固有の言語処理系とビルド依存。可能なら各プロジェクトの `flake.nix` / `devShell` で管理する

### `install/host` の扱い

`install/host` は移植対象とはしない。Ubuntu デスクトップ全体の再現性を高めようとした過去の残骸として扱う。

移行中に次の情報だけを監査する。

- Home Manager へ移すべき CLI パッケージ
- Nix 導入に必要な最小限の bootstrap 手順
- OS 側に残す作業の備忘録

必要な情報を回収した後は、`install/host` を削除するか `docs/legacy/` へ隔離する。スクリプトを Nix 式へ機械的に翻訳しない。

## 採用する構成

Ubuntu と macOS では standalone Home Manager を使う。macOS のシステム設定まで管理する必要が出るまでは nix-darwin を導入しない。

NixOS では Home Manager を NixOS module として統合しても、standalone のまま運用してもよい。ただし Home Manager module 本体はどちらからでも再利用できる構造にする。

想定するディレクトリ構成は次のとおり。

```text
projects/dotfiles/
├── flake.nix
├── flake.lock
├── hosts/
│   ├── ubuntu.nix
│   ├── nixos-minimal.nix
│   └── macos.nix
├── modules/
│   ├── common.nix
│   ├── linux.nix
│   ├── darwin.nix
│   ├── zsh.nix
│   ├── cli.nix
│   ├── git.nix
│   ├── tmux.nix
│   ├── neovim.nix
│   └── ghostty.nix
├── dot_config/
│   ├── nvim/
│   ├── tmux/
│   ├── ghostty/
│   ├── fcitx5/
├── bootstrap/
├── docs/
└── legacy/
```

`hosts/*` は「端末の種類と役割」を選び、`modules/*` は再利用可能な機能単位を表す。ホスト名による条件分岐を各設定へ散らさず、ホスト側の `imports` で構成を合成する。

## ホストごとの役割

### Ubuntu desktop

- 共通の shell、Git、tmux、Neovim、CLI を有効化する
- Ghostty の設定を配置する
- 必要なら fcitx5 のユーザー設定を配置する
- Ghostty 本体や GUI アプリの導入は Ubuntu 側に任せてもよい

### NixOS minimal

- 共通の shell、Git、tmux、Neovim、CLI を有効化する
- GUI アプリ、Ghostty、フォントを含めない
- SSH 先で実際に動くプログラムだけを管理する
- Flakes は NixOS の system configuration に次を設定する

```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

### macOS

- standalone Home Manager で共通の開発環境を有効化する
- macOS 固有設定は `darwin.nix` に分離する
- Apple Silicon は `aarch64-darwin`、Intel Mac は `x86_64-darwin` を使用する
- システム設定を宣言管理したくなるまでは nix-darwin を導入しない

## 作業時間の方針

1回の作業を休日の最大3時間に収まる単位へ分割する。各セッションは、未完成の大変更ではなく、buildまたはswitchできる小さな成果で終了する。

1セッションの基本形は次のとおり。

1. 対象を1機能または1アプリに限定する
2. 変更前の挙動と管理元を確認する
3. Home Managerへ移す
4. `nix flake check`と対象configurationのbuildを行う
5. 可能ならswitchしてsmoke testする
6. 次の作業をチェックリストへ残す

シェル選定、diffツール自作、プラグインの大幅変更のような調査が必要な項目は、移行作業と同じセッションへ詰め込まない。

## 設定ファイルの方針

アプリ固有の設定は、無理に Nix 構文へ翻訳しない。

- Neovim は Lua のまま維持する
- tmux は既存の tmux.conf を基本にする
- Ghostty は既存形式の設定を基本にする
- Nix はパッケージの導入、配置、ホスト差分の合成を担当する

例えば Neovim は次のようにディレクトリを配置する。

```nix
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  xdg.configFile."nvim" = {
    source = ../dot_config/nvim;
  };
}
```

Ghostty は Ubuntu desktop と macOS だけで `ghostty.nix` を import する。Ubuntu 上の Ghostty から NixOS minimal へ SSH する場合も、Ghostty の設定は Ubuntu 側にのみ配置する。NixOS 側では tmux、shell、Neovim、terminfo などリモートで必要なものだけを扱う。

## chezmoi テンプレートの置き換え

現在のテンプレートが持つ主な差分軸のうち、移行後も扱うものは次の2つである。

- Linux
- macOS

Dev Containerは最近利用していないため移行対象外とし、既存の分岐や導入スクリプトも引き継がない。

`{{ if ... }}` をそのまま Nix の文字列テンプレートへ移植するのではなく、次の順で解消する。

1. 共通部分を通常の設定ファイルへ抜き出す
2. Linux/macOS 差分を `linux.nix` と `darwin.nix` へ分離する
3. GUI の有無をホストの import で表現する
4. 小さな値の差分だけ `lib.mkIf`、`lib.optionals`、`lib.optionalString` を使う

Git の氏名、メールアドレスなどのホスト・所属依存値は、共通モジュールへ直接埋め込まずホスト設定から渡す。credentialや秘密情報はFlakeへ含めない。Flakeの内容はNix storeへコピーされ、他ユーザーから読める可能性があるためである。

## パッケージ管理の方針

パッケージは用途別に置き場所を決める。

| 種類 | 管理場所 |
| --- | --- |
| Git、Neovim、tmux、fzf、fdなど常用CLI | Home Manager |
| jujutsuなど常用するVCSツール | Home Manager |
| GUIアプリ、ドライバ、system daemon | Ubuntu/macOS |
| プロジェクト固有のNode.js、Python、Rust、ライブラリ | 各プロジェクトのdevShell |
| Neovimから常用する汎用LSP、formatter、linter | Home Manager |
| プロジェクト固有のLSP、formatter、言語処理系 | 各プロジェクトのdevShell |

最初からmiseを廃止すること自体は目標にしない。ただしMasonの代替としてmiseから供給しているLSP、formatter、linterはNixへ移す。常用するものはHome Managerへ、プロジェクト固有のものはdevShellへ移し、既存プロジェクトの言語バージョン管理など残った用途だけmiseを継続する。役割がなくなれば最終的にmiseを撤去する。

## 段階的な移行手順

### Phase 0: 現状の固定と棚卸し

- chezmoiで生成されたファイルと、その入力テンプレートを対応付ける
- `install/host` とmiseから、実際に使用中のCLI一覧を抽出する
- Ubuntu desktop、NixOS minimal、macOSで必要な機能を表にする
- Git identityや仕事用設定など、公開リポジトリへ置けない値を特定する
- `nix-shell`で発生しているmise・ble.shのエラーを再現し、smoke testとして記録する

完了条件：移行対象、OS側に残す対象、廃止候補が分類されている。

### Phase 1: Home Managerの骨格

- `flake.nix`、`flake.lock`を追加する
- `homeConfigurations`にUbuntu、NixOS minimal、macOSを定義する
- `home.stateVersion`は初回導入時の値を固定し、Nixpkgs更新時に安易に変更しない
- 共通モジュールとOS別モジュールを作る
- `nix flake check`で評価できるようにする

Ubuntu/macOSのFlakes設定はHome Manager側で管理できる。NixOSではsystem configurationの`nix.settings`を正とし、`~/.config/nix/nix.conf`との重複を最終的に解消する。

完了条件：既存dotfilesを置き換えず、全ホスト構成が評価できる。

### Phase 2: zshによるshell基盤

- zshをHome Manager管理へ移す
- bash + ble.shおよびsheldonは移植せず、zshの補完、autosuggestion、syntax highlightingで必要な操作感を構成する
- 既存 `.bashrc` から必要なalias、環境変数、prompt、カスタム関数だけを回収する
- fzfとdirenv/nix-direnvのzsh連携を有効にする
- `nix-shell -p jujutsu`と通常のlogin shellがエラーなく起動することを確認する
- macOSでは`/bin/zsh`、UbuntuではOS側の`/usr/bin/zsh`をlogin shellとし、Nix store内のパスをlogin shellへ直接指定しない
- vi modeで`Ctrl-C`をsignalとして扱う要件をテスト項目にする

完了条件：オプションツールの有無にかかわらずshellが起動し、補完と基本キーバインドが利用できる。

### Phase 3: Neovim、tmux、fzf

- `home/dot_config/nvim`を`dot_config/nvim`へ移す
- Luaは書き換えず、Home Managerで配置する
- Neovim本体と必須CLIをHome Managerへ追加する
- 現在miseで導入しているLSP、formatter、linterを棚卸しし、Neovim専用ツールは`programs.neovim.extraPackages`、shellからも使うものは`home.packages`へ移す
- Neovim設定からmiseのインストール先への絶対パス参照をなくし、`PATH`上の実行ファイル名で起動する
- プロジェクト固有のLSPと言語処理系はdevShellから供給し、direnv/nix-direnv経由でNeovimから利用できることを確認する
- UbuntuとNixOS minimalの双方で起動・LSP・clipboard挙動を確認する
- tmux設定を通常ファイルへし、macOS clipboard差分を分離する
- fzfと`ghq-path`/`dev`関数の連携を復元する
- AI作業用のtmux session構成は、基本環境が動いた後に小さなworkflowとして追加する

完了条件：chezmoiなしでNeovim、tmux、fzfが動き、SSH先で基本的な開発作業ができる。

### Phase 4: GitとVCS

- Gitの一般設定は`programs.git`へ移す
- identityはホスト設定または別の非公開設定から渡す
- ghqのroot、clone、fzfによるrepository移動をHome Manager環境で再現する
- 現在利用していないgwqとGit worktree workflowは移行対象から外す
- jujutsuの設定は日常利用を始めるまでバックログへ置く
- Git diff/reviewツールは既存候補を評価する。difitのforkや自作は別プロジェクトとして判断し、Home Manager移行をブロックさせない

完了条件：Gitの基本操作とghqによるrepository管理が再現できる。

### Phase 5: その他の設定

- GhosttyはGUIホストだけに配置する
- 旧mise設定は常用CLI、project固有runtime、廃止対象へ分解し、mise自体を残す必要がなければ撤去する
- fcitx5、VSCode Neovim設定を必要に応じて順次移す
- 各アプリについて「Home Manager moduleを使う」「元ファイルを配置する」の単純な方を選ぶ
- OS固有差分はホストまたはOSモジュールへ閉じ込める

完了条件：`home/`以下のchezmoiソースがHome Manager管理へ移っている。

### Phase 6: パッケージの整理

- 常用CLIをmise/aqua/手動インストールからHome Managerへ移す
- プロジェクト固有の処理系を各プロジェクトのdevShellへ移す
- Ubuntu側とNix側に同じ実行ファイルがある場合、`type -a <command>`でPATH競合を確認する
- Linux/Darwinで提供状況が異なるパッケージを共通モジュールから分離する

完了条件：各ツールの管理元が一つに定まり、miseには意図したものだけが残る。

### Phase 7: chezmoiとlegacyの撤去

- アプリ単位でchezmoiの管理対象から外す
- 全ホストでHome Managerのswitchとrollbackを確認する
- chezmoiテンプレートと導入処理を削除する
- `install/host`から有効な情報をdocsまたはbootstrapへ回収する
- 残骸を削除または`legacy/`へ隔離する
- READMEを新しいbootstrap・適用手順へ更新する

完了条件：chezmoiなしで開発環境を再構築でき、`install/host`を通常運用で使わない。

## 移行後の機能バックログ

以下は重要だが、Home Manager移行の完了条件には含めない。基盤を壊さず、一項目ずつ追加する。

### Shell

- 補完とvi-like key bindingを整備する
- vi mode中でも`Ctrl-C`が期待どおりsignalとして働くことを確認する
- zshのpromptへ色を付け、現在のdirectoryとGit branchを見分けやすく表示する
- prompt設定はHome Managerが生成する`.zshrc`から読み込める独立したzshファイルにし、Git repository外でもエラーなく動くことを確認する
- shell履歴をfzfで絞り込み、選択したコマンドを編集してから実行できる履歴検索を追加する
- 履歴検索のkey binding、複数行commandの扱い、fzfをキャンセルした場合の挙動をsmoke testする

### tmuxとAI workflow

- AI開発用のsession/window/pane構成を決める
- Linux、SSH、Ghosttyで同じ操作感になることを優先する
- 特定のterminal固有機能を必須依存にしない

### Terminal rendering

- Ghostty上で利用できるMarkdown viewerを選定する
- Mermaidをterminalで表示する方法を調査する
- renderer本体はHome Manager、Ghosttyの表示設定はGUIホスト側に置く

### Neovim

- Vueの`<template>`補完を含むVue.js対応
- React、React Native対応
- wrap optionの見直し
- Rust、Go対応
- code review workflow
- Octo.nvim
- trouble.nvim

プラグイン追加より先に、既存Lua設定を移行した状態での起動、補完、LSP、formattingをsmoke testできるようにする。

### Credential管理

- KeePassXCまたは1Password CLIを比較する
- credential本体をNix storeやGitへ保存しない
- Home ManagerはCLIや連携設定だけを管理し、秘密情報は外部のsecret storeから実行時に取得する

### VCSとdiff

- jujutsuを日常workflowで試す
- Git worktreeやgwqが再び必要になった時点で、ghqとの役割分担を整理する
- terminal向けのdiff/code reviewツールを評価する
- difitの代替がなければ、forkまたは自作を独立した課題として起票する

## 移行時の安全策

- 一度にすべてを切り替えず、Neovim、Git、tmuxのようにアプリ単位で所有権を移す
- Home Managerが既存ファイルとの衝突を報告した場合、内容を比較してから移動またはbackupする
- `force = true`は原則使わない。ローカル変更を黙って失う可能性がある
- 初回switch前に、chezmoiが生成した現在の設定を退避できる状態にする
- 各Phaseで`nix flake check`と対象ホストのbuildを行い、switch前に評価エラーを検出する
- NixOS minimalへは、可能なら現在のSSHセッションを残したまま別セッションで動作確認する
- FlakeやNix storeへcredential、秘密鍵、アクセストークンを含めない

## 最終的な運用

通常の変更は次の流れに統一する。

1. このリポジトリ内のNix moduleまたは元形式の設定ファイルを編集する
2. `nix flake check`を実行する
3. 対象ホストのHome Manager構成をbuildする
4. `home-manager switch --flake ...`で反映する
5. 問題があれば前のgenerationへrollbackする

NixOSへHome Managerをmodule統合した場合のみ、NixOS側は`nixos-rebuild`からまとめて反映する。UbuntuとmacOSはstandalone Home Managerを維持する。

## 成功条件

- Ubuntu desktop、NixOS minimal、macOSで共通のターミナル開発体験を再現できる
- Ubuntu上のGhosttyなど、GUIホストだけに必要な設定がSSH先へ導入されない
- Neovim設定はLuaのまま読みやすく保たれている
- ホスト差分がテンプレート内へ散らばらず、host/moduleのimportで把握できる
- 日常的なCLIとdotfilesの管理元がHome Managerに統一されている
- OS全体をNix化する保守負担を背負わず、開発環境に必要な再現性を得られている
