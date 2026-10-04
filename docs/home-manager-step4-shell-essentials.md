# Home Manager Step 4: 日常利用するshell設定を移す

## この手順のゴール

Step 3でzshをログインシェルにした。このStepでは、既存`.bashrc`から日常利用に必要な設定だけをzsh環境へ移す。

移行するもの：

- `EDITOR`と`VISUAL`
- `n` alias
- `ghq-path`関数
- `dev`関数
- 関数が依存するNeovim、ghq、tmux

移行しないもの：

- Ubuntu標準`.bashrc`の雛形
- ble.shとsheldon
- bash用completionと履歴処理
- bash用prompt
- Dev Container用処理
- miseと言語処理系、LSP

「以前の`.bashrc`をzshへ翻訳する」のではなく、現在も必要な機能だけを新しい管理方法で作り直す。

## 1. 既存設定を分類する

既存`.bashrc`の主な設定は次のように分類できる。

| 既存設定 | 扱い |
| --- | --- |
| `ll`、`la`、`lla`、`gs`、`c` | Step 2で移行済み |
| bash履歴共有 | zshの`history.share`で置換済み |
| `set -o vi` | `defaultKeymap = "viins"`で置換済み |
| `eval "$(fzf --bash)"` | `programs.fzf.enableZshIntegration`で置換済み |
| ble.sh | zshでは不要 |
| sheldon | 現時点では不要 |
| `EDITOR=nvim`、`n` | このStepで移行 |
| `ghq-path`、`dev` | このStepで移行 |
| `LANG`、`LC_*` | OSのlocale設定を優先し、このStepでは移植しない |
| mise | 後のNeovim/LSP移行で整理 |
| bash prompt | 後で必要性を判断 |

現在のlocaleは次で確認できる。

```zsh
locale
```

NixOS側ですでに期待する値になっているなら、同じ値をHome Managerから重ねて設定しない。macOSでは利用可能なlocale名が異なる可能性もあるため、`LANG=C.UTF-8`などを共通moduleへ無条件に移植しない。

## 2. 常用パッケージをHome Managerへ追加する

`modules/common.nix`を次のように変更する。

```nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ghq
    neovim
    ripgrep
    tmux
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
```

`home.sessionVariables`は特定のshell構文ではなく、Home Managerが管理するユーザー環境の変数として宣言する。これにより、将来macOSでも同じHome Manager moduleを再利用できる。

この段階ではNeovimとtmuxの設定までは移さない。まず実行ファイルだけをHome Managerの管理へ移し、設定は後のStepでアプリ単位に扱う。

NixOS側にも同じパッケージが入っている場合、一時的に重複してもよい。Home Manager側で正常に使えることを確認してから、後でNixOS側のパッケージ一覧から外す。

## 3. zsh関数を通常のzshファイルとして作る

複雑なshellコードをNix文字列へ埋め込まず、`dot_config/zsh/functions.zsh`を作る。

```zsh
function ghq-path() {
  ghq list --full-path | fzf
}

function dev() {
  local moveto
  moveto="$(ghq-path)" || return

  # fzfをEscなどでキャンセルした場合は何もしない。
  [[ -n "$moveto" ]] || return

  cd -- "$moveto" || return

  if [[ -n "$TMUX" ]]; then
    local repo_name="${moveto##*/}"
    tmux rename-session "${repo_name//./-}"
  fi
}
```

既存bash版では`cd`失敗時に`exit 1`していたが、ログインシェルで`exit`するとshell自体が終了する。zsh版では関数だけを終了する`return`へ変更する。

`fzf`をキャンセルして空文字になった場合の確認も追加する。これにより、キャンセル時に意図せずホームディレクトリへ移動することを防ぐ。

## 4. zsh moduleから関数ファイルを読み込む

`modules/zsh.nix`の`programs.zsh`へ`initContent`と`n` aliasを追加する。

該当部分は次の形になる。

```nix
{ config, ... }:

{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = true;

    # 既存のautosuggestion、historyなどはそのまま残す。

    shellAliases = {
      ll = "ls -alF";
      la = "ls -A";
      lla = "ls -la";
      gs = "git status";
      c = "clear";
      n = "nvim";
    };

    initContent = builtins.readFile ../dot_config/zsh/functions.zsh;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
```

`builtins.readFile`は、zshファイルの内容をHome Managerが生成する`~/.zshrc`へ取り込む。最終的な配置先は引き続き`~/.zshrc`だが、関数はzshとして読みやすいファイルで編集できる。

```text
modules/zsh.nix
dot_config/zsh/functions.zsh
           ↓ Home Managerが合成
        ~/.zshrc
```

## 5. 新規ファイルをGitへ登録する

Flakeが新しい関数ファイルを入力として認識できるようにする。

```bash
git add modules/common.nix modules/zsh.nix dot_config/zsh/functions.zsh
```

新しいファイルを`git add`し忘れると、build時にNix store内で`functions.zsh`が見つからないというエラーになる。

## 6. buildして生成結果を確認する

```bash
nix build '.#homeConfigurations."hwata@nixos".activationPackage'
```

buildに成功したら、生成された`.zshrc`に関数が含まれていることを確認する。

```bash
rg -n 'ghq-path|function dev' result/home-files/.zshrc
```

まだホーム環境へは反映されていない。

## 7. switchして新しいログインzshを起動する

```bash
home-manager switch --flake '.#hwata@nixos'
```

現在のzshは起動時に読み込んだ古い設定を保持している。`source ~/.zshrc`でも一部は反映できるが、session variableや初期化順も含めて確認するため、新しいlogin shellを起動する。

現在のSSH接続を残したまま別のSSH接続を開くのが最も安全である。現在の端末内で切り替えるなら次を使う。

```zsh
exec zsh -l
```

`~/.zshrc`をbashから`source`してはいけない。zsh専用構文がbashでエラーになる可能性がある。

## 8. session variableとパッケージを確認する

```zsh
echo $EDITOR
echo $VISUAL

command -v nvim
command -v ghq
command -v tmux
command -v rg
```

Home Manager profileの実行ファイルが優先されているか確認する。

```zsh
type -a nvim
type -a ghq
type -a tmux
```

NixOS側とHome Manager側の両方が表示されても、移行期間中は問題ない。先頭に表示されるものが実際に実行される。

aliasも確認する。

```zsh
alias n
n --version
```

## 9. 関数をsmoke testする

関数が読み込まれたことを確認する。

```zsh
type ghq-path
type dev
```

`ghq-path`を実行し、fzfからリポジトリを選択できることを確認する。

```zsh
ghq-path
```

次に`dev`を実行し、選択したリポジトリへ移動できることを確認する。

```zsh
dev
pwd
```

fzfを`Esc`でキャンセルしても、shellが終了せず、現在のディレクトリも変わらないことを確認する。

tmux内でも`dev`を実行し、session名が選択したリポジトリ名へ変わることを確認する。

## 10. 問題がなければcommitする

```bash
git diff -- modules/common.nix modules/zsh.nix dot_config/zsh/functions.zsh
git diff --cached -- modules/common.nix modules/zsh.nix dot_config/zsh/functions.zsh
git status
```

期待どおりならcommitする。

```bash
git add modules/common.nix modules/zsh.nix dot_config/zsh/functions.zsh
git commit -m "Migrate essential shell settings to zsh"
```

## miseをまだ有効化しない理由

既存`.bashrc`は次を無条件に実行していた。

```bash
eval "$(~/.local/bin/mise activate bash)"
```

しかし現在のNixOSには、そのパスにmiseが存在しない。この処理をそのままzshへ移すと、以前と同じshell起動エラーを再発させる。

また、既存mise設定には次が混在している。

- Node.js、Python、Rust、Goなどの言語処理系
- Neovim用LSP
- Neovim、fzf、fd、batなどの常用CLI
- Codex、ghq、gwqなどのツール

これらは一括して移植せず、次の原則で後から分解する。

- 全端末で常用するCLI: Home Manager
- Neovimから常用する汎用LSP: Home Manager
- プロジェクト固有の処理系とLSP: devShell
- 既存プロジェクトでmiseが必要なもの: 当面miseを継続

Step 4ではmiseを起動経路へ戻さず、まず壊れないログインzshを維持する。

## このStepではまだ行わないこと

- 既存bash設定の削除
- NixOS system packagesからNeovim、ghq、tmuxを削除
- miseの導入・削除
- LSPの移行
- Neovimとtmuxの設定移行
- promptの変更

## 完了条件

- `EDITOR`と`VISUAL`が`nvim`になる
- `n`でNeovimを起動できる
- Neovim、ghq、tmuxがHome Managerから利用できる
- `ghq-path`と`dev`がzshから利用できる
- fzfのキャンセル時にshellや作業ディレクトリへ影響しない
- tmux内で`dev`を使うとsession名が変わる
- miseがなくても新しいログインzshがエラーなく起動する
- bashと既存bash設定はまだ残っている

Step 4完了後は、[`home-manager-step5-neovim.md`](./home-manager-step5-neovim.md)へ進み、Neovim設定をLuaのままHome Managerへ移して、現在miseから供給しているLSPをNixへ移す準備をする。
