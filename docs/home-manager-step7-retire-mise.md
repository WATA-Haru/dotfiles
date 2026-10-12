# Home Manager Step 7: mise設定を解体して常用CLIを移す

## この手順のゴール

旧mise設定をHome Managerへ丸ごと翻訳するのではなく、各ツールを用途別に分類する。

- 全端末で使うCLIはHome Managerへ移す
- プロジェクト固有の言語runtimeは各projectのdevShellへ任せる
- Home Managerへ移行済みの重複項目は再追加しない
- 現在使っていないツールは「念のため」で導入しない
- NixOSの有効な環境からmiseへの依存をなくす

このStepでは、リポジトリ直下の`mise.toml`が管理している`yazi`をHome Managerへ移し、旧mise設定にあった`bat`、`fd`、`gh`も常用CLIとして追加する。

mise本体をHome Managerへ導入するStepではない。

## 現在の状態

現在のNixOSではmiseは導入されていない。

```zsh
command -v mise
```

何も表示されないのが現在の正常な状態である。

リポジトリ直下の`mise.toml`は次の内容だけを持つ。

```toml
[tools]
yazi = "latest"
```

しかしmise本体がないため、このファイルから`yazi`は導入されていない。

一方、旧chezmoi設定の`home/dot_config/mise/config.toml.tmpl`には、言語runtime、LSP、CLI、shell plugin managerが混在している。これを一つのNix moduleへ機械的に移植しない。

## 1. Step 6を完了して変更を区切る

Step 7を始める前に、Step 6のLSPとTreesitterが動作することを確認する。

```zsh
nvim --headless \
  "+lua for _, cmd in ipairs({ 'lua-language-server', 'pyright-langserver', 'vtsls', 'tree-sitter', 'cc' }) do print(cmd .. ': ' .. vim.fn.exepath(cmd)) end" \
  '+qa'
```

各commandにパスが表示されることを確認する。実際に使用するLua、Python、TypeScript、Vue projectでも必要なLSPがattachすることを確認する。

次に現在の差分を確認する。

```zsh
git status
git diff
git diff --cached
```

Step 6の変更が期待どおりなら、Step 7と混ざらないよう先にcommitする。意図したファイルを個別に`git add`するか、`git add -p`で選んでstageする。未確認の変更をまとめて`git add -A`しない。新規文書など`git add -p`で拾えないファイルは名前を指定して追加する。

```zsh
git status --short
git diff --cached
git commit -m "Migrate Neovim language servers to Nix"
```

すでにcommit済みならこの操作は不要である。

## 2. 旧mise設定を分類する

`home/dot_config/mise/config.toml.tmpl`の各項目を次のように扱う。

| 旧mise項目 | 方針 | 理由 |
| --- | --- | --- |
| `lua-language-server` | Step 6で移行済み | `programs.neovim.extraPackages`から供給する |
| `@vtsls/language-server` | Step 6で移行済み | 同上 |
| `@vue/language-server` | Step 6で移行済み | 同上 |
| `@aca/emmet-ls` | Step 6で移行済み | Nixpkgsの`emmet-language-server`を使う |
| Neovim | 移行済み | `programs.neovim`で管理している |
| fzf | 移行済み | `programs.fzf`で管理している |
| ghq | 移行済み | `modules/common.nix`で管理している |
| yazi | このStepで移行 | `programs.yazi`を使う |
| bat | このStepで移行 | `programs.bat`を使う |
| fd | このStepで移行 | `programs.fd`を使う |
| `cli/cli` (`gh`) | このStepでpackageを移行 | 認証設定はまだHome Manager管理にしない |
| Node.js、Python、Go、Rust、pnpm | globalには移行しない | projectごとのdevShellで必要なversionを選ぶ |
| Codex | 保留 | 現在はNixOS system側から供給されており、実行環境の移行を別に確認する |
| gwq | 保留 | configとworkflowをまとめて後のStepで移す |
| vim-startuptime | 保留 | 常用していることを確認してから追加する |
| sheldon | 廃止 | zshの補完などはHome Managerのzsh moduleで構成済み |
| Dev Container CLI | 移行しない | Dev Containerは移行対象外と決めている |
| aqua | 移行しない | package manager自体をNixへ持ち込む必要はない |

「以前の設定に書いてあった」という理由だけで全項目を導入しない。

## 3. CLI用moduleを作る

`modules/cli.nix`を作る。

```nix
{ pkgs, ... }:

{
  # packageだけを管理し、~/.config/ghと認証情報には触れない。
  home.packages = with pkgs; [
    gh
  ];

  programs.bat.enable = true;
  programs.fd.enable = true;

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";
  };
}
```

`programs.yazi.enableZshIntegration`は、Yazi終了時に選択中のdirectoryへshell側も移動できるwrapper functionを追加する。直接起動する`yazi`と、directory移動用の`y`を使い分けられる。

`shellWrapperName`は現在の`home.stateVersion = "26.05"`では既定値も`y`だが、使用するcommand名を明確に固定するため明記する。

### なぜ`programs.gh.enable`をまだ使わないのか

`programs.gh.enable = true`は`gh`本体だけでなく、`~/.config/gh/config.yml`とGit credential helperも管理する。既存の設定ファイルがある場合はHome Managerのswitch時に衝突し、Git設定の所有権移行も同時に発生する。

このStepではpackageの供給元だけを変えるため、`home.packages = [ pkgs.gh ]`を使う。`~/.config/gh/hosts.yml`などの認証情報は表示、コピー、Nix storeへの格納をしない。Git設定を移すStepで`programs.gh`への切り替えを改めて検討する。

## 4. NixOSホストからCLI moduleを読み込む

`hosts/nixos.nix`の`imports`へ`cli.nix`を追加する。

```nix
imports = [
  ../modules/cli.nix
  ../modules/common.nix
  ../modules/neovim.nix
  ../modules/zsh.nix
];
```

importの順番には依存させない。ここでは機能を見つけやすくするため、ファイル名順に並べている。

UbuntuとmacOSのHome Manager configurationを追加するときも、これらのCLIが必要なら同じ`cli.nix`をimportできる。

## 5. 新しいmoduleをGitへ登録する

FlakeはGit管理外のファイルを入力として認識しないため、build前に新規ファイルを登録する。

```zsh
git add modules/cli.nix hosts/nixos.nix
git status --short
```

この時点では`mise.toml`をまだ削除しない。Home Manager版Yaziのbuildと動作確認を先に行う。

## 6. switchせずにbuildする

```zsh
nix build '.#homeConfigurations."hwata@nixos".activationPackage'
```

生成されたprofileにcommandがあることを確認する。

```zsh
for cmd in yazi bat fd gh; do
  test -x "result/home-path/bin/$cmd" && echo "found: $cmd"
done
```

4個すべてについて`found:`が表示されればよい。

versionもbuild結果から直接確認できる。

```zsh
result/home-path/bin/yazi --version
result/home-path/bin/bat --version
result/home-path/bin/fd --version
result/home-path/bin/gh --version
```

この段階では現在のprofileや`~/.config/gh`は変更されない。

## 7. Home Managerをswitchする

```zsh
home-manager switch --flake '.#hwata@nixos'
```

packageの供給元を確認する。

```zsh
type -a yazi
type -a bat
type -a fd
type -a gh
```

少なくとも先頭が`/home/hwata/.nix-profile/bin/`以下になっていれば、Home Manager版が優先されている。

現在のNixOSでは`gh`が`/run/current-system/sw/bin/gh`にも存在するため、二つ表示されてもこのStepでは問題ない。NixOS system側の重複削除は、`/etc/nixos/configuration.nix`をdotfiles側へ移す段階で行う。

## 8. 新しいzshでYazi integrationを確認する

Yaziの`y` functionはshell起動時に定義されるため、新しいlogin shellを起動する。

```zsh
exec zsh -l
```

確認する。

```zsh
type y
yazi --version
```

`y is a shell function`に相当する表示になればintegrationが読み込まれている。

実際に`y`を起動し、directoryを移動して終了した後、shell側のworking directoryも変わることを確認する。

```zsh
y
pwd
```

通常の`yazi` commandも起動・終了できることを確認する。

## 9. bat、fd、ghをsmoke testする

```zsh
bat --version
fd --version
gh --version
```

`bat`はこのリポジトリのファイルで表示を確認できる。

```zsh
bat flake.nix
```

`fd`も検索範囲を限定して確認する。

```zsh
fd --type f --max-depth 2 . modules
```

GitHub CLIは既存の認証状態を確認する。

```zsh
gh auth status
```

未認証なら、その旨が表示されてもpackage移行自体は成功している。認証が必要になった時点で`gh auth login`を実行する。tokenや`~/.config/gh/hosts.yml`の内容をterminalへ表示したり、Gitへ追加したりしない。

## 10. ルートの`mise.toml`を削除する

Home Manager版Yaziが動作した後、リポジトリ直下の`mise.toml`を確認する。

```zsh
git diff -- mise.toml
sed -n '1,80p' mise.toml
```

引き続き`yazi = "latest"`だけであることを確認してから、Git管理下から削除する。

```zsh
git rm mise.toml
```

これは設定ファイルを削除するだけで、Yazi本体を削除する操作ではない。以後YaziはHome Managerが供給する。

## 11. 有効な設定にmise参照がないことを確認する

現在のNixOSで読み込まれる範囲だけを検索する。

```zsh
rg -n '\bmise\b|mise/installs' \
  flake.nix hosts modules dot_config
```

何も表示されなければよい。

リポジトリ全体を検索すると、docs、`home/dot_bashrc.tmpl`、`home/dot_config/mise/config.toml.tmpl`、`install/`にはまだmiseの記録が見つかる。これはこのStepでは想定内である。

```zsh
rg -n '\bmise\b|mise/installs' .
```

旧ファイルを見つけても、この時点で一括削除しない。

## 12. 旧chezmoiのmise設定はまだ削除しない

`home/dot_config/mise/config.toml.tmpl`と`home/dot_bashrc.tmpl`は、Ubuntu側の現在の環境で使われている可能性がある。NixOSでmiseが不要になったことだけを根拠に削除すると、Ubuntu側のNode.jsやPythonなどが突然使えなくなる可能性がある。

削除条件は次のとおり。

- Ubuntu用Home Manager configurationが作成されている
- Ubuntuで必要な常用CLIがHome Managerから使える
- Ubuntuのprojectが必要とするruntimeの供給元を確認している
- chezmoiがmise設定とbash設定を管理しなくても日常作業できる
- macOSでmiseを継続するprojectがないか確認している

条件を満たした後、chezmoiの管理対象から外して旧templateを削除する。それまではlegacy入力として残すが、新しいNixOS設定からは参照しない。

## 13. 変更を確認してcommitする

```zsh
git status
git diff --stat
git diff --cached --stat
git diff -- modules/cli.nix hosts/nixos.nix mise.toml
git diff --cached -- modules/cli.nix hosts/nixos.nix mise.toml
```

特に次を確認する。

- `modules/cli.nix`が追加されている
- `hosts/nixos.nix`が`cli.nix`をimportしている
- 削除する`mise.toml`にはYazi以外の設定がなかった
- `home/dot_config/mise/config.toml.tmpl`はまだ残っている
- credentialやtokenを追加していない

問題なければcommitする。

```zsh
git add modules/cli.nix hosts/nixos.nix
git commit -m "Move common CLI tools from mise to Home Manager"
```

`git rm mise.toml`を実行済みなら、削除はすでにstageされている。

## CodexをこのStepで移さない理由

現在のNixOSでは`codex`は`/run/current-system/sw/bin/codex`から供給されている。固定中のNixpkgsにも`codex` packageは存在するが、実行中のagent自体の供給元を同じ作業中に変更すると、不具合時の切り分けが難しくなる。

CodexをHome Managerへ移す場合は、次を確認する独立した小さな変更にする。

- Nixpkgs版のversionが必要な機能を満たす
- login、設定、plugin、skillの保存場所が変わらない
- system版とHome Manager版のどちらが優先されるか
- rollback後もCodexを起動できる

このStepではsystem版をそのまま利用する。

## 言語runtimeが必要になった場合

Node.js、Python、Go、RustをHome Managerへglobalに追加する前に、そのruntimeを必要とするprojectへdevShellを作る。

```text
project/
├── flake.nix
├── flake.lock
└── source files
```

project directoryで次の形にする。

```zsh
nix develop
nvim .
```

devShellの`PATH`がNeovimへ引き継がれ、Home Manager版LSPからproject固有runtimeと依存関係を参照できる。具体的なdevShell作成は別Stepとし、Step 7では架空の共通versionを決めない。

既存projectがmiseの`.mise.toml`を実際に使っている場合は、そのprojectをdevShellへ移すまでmiseを残してもよい。miseを残すことと、dotfiles全体をmiseへ依存させることは別である。

## 問題があった場合の戻し方

CLI moduleで問題が起きた場合は、`hosts/nixos.nix`から`../modules/cli.nix`のimportを外し、buildとswitchを行えば以前のgenerationへ戻せる。

```zsh
home-manager generations
```

Yaziが必要なら、`mise.toml`の削除をcommitする前はGitから復元できる。ただし現在のNixOSにはmise本体がないため、ファイルを戻すだけではYaziは起動しない。基本的にはHome Manager generationを戻して原因を直す。

既存の`~/.config/gh`はこのStepでHome Manager管理にしていないため、rollback時にもそのまま残る。

## このStepではまだ行わないこと

- Home Managerへのmise本体の導入
- 旧chezmoiのmise template削除
- `~/.local/share/mise`などcacheの削除
- Node.js、Python、Go、Rust、pnpmのglobal導入
- Codexの供給元変更
- gwq設定の移行
- `programs.gh`によるGitHub CLI設定・credential helperの管理
- projectごとのdevShell作成
- NixOS system packagesから重複CLIを削除

## 完了条件

- `yazi`、`bat`、`fd`、`gh`がHome Managerから導入されている
- 新しいzshで`y` wrapperを利用できる
- Yazi終了後のdirectory移動が動く
- `gh auth status`を実行でき、既存認証情報を失っていない
- リポジトリ直下の`mise.toml`が削除されている
- NixOSで有効な`flake.nix`、`hosts`、`modules`、`dot_config`にmise参照がない
- `command -v mise`が失敗しても日常的なCLIとNeovim/LSPを利用できる
- 言語runtime、Codex、gwqなどの保留理由が明確になっている
- Ubuntu/macOSで使う可能性がある旧chezmoi templateは回復可能な状態で残っている

Step 7完了後は、[`home-manager-step8-tmux.md`](./home-manager-step8-tmux.md)へ進み、tmux設定をHome Managerへ移す。Ubuntu用Home Manager configurationを作る段階で、残してある旧mise templateを本当に削除できるか再確認する。
