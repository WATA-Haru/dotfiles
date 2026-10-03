# Home Manager Step 2: zshを安全に試す

## この手順のゴール

既存のbash環境を残したまま、Home Managerが管理するzshを手動で起動し、次を確認する。

- zsh本体と設定をHome Managerで導入できる
- Home Managerが最終的な設定を`~/.zshrc`へ配置する
- 補完、履歴共有、autosuggestion、syntax highlightingが動く
- vi keymapで基本的な編集ができる
- 問題があれば`exit`するだけでbashへ戻れる

このStepでは、ログインシェルの変更、既存`.bashrc`の削除、chezmoiからの所有権移行は行わない。

## 現在の状態

`hosts/nixos.nix`では、すでにzsh moduleをimportしている。

```nix
imports = [
  ../modules/common.nix
  ../modules/zsh.nix
];
```

現在の`modules/zsh.nix`は、zshパッケージを直接追加している。

```nix
{ pkgs, ... }:

{
  home.packages = [
    pkgs.zsh
  ];
}
```

これはzshコマンドを導入するだけで、`.zshrc`などの設定は管理しない。Step 2ではHome Managerの`programs.zsh` moduleへ置き換える。

## 1. `programs.zsh`を有効にする

`modules/zsh.nix`を次の内容に置き換える。

```nix
{ config, ... }:

{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = true;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    defaultKeymap = "viins";

    history = {
      size = 100000;
      save = 100000;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    shellAliases = {
      ll = "ls -alF";
      la = "ls -A";
      lla = "ls -la";
      gs = "git status";
      c = "clear";
    };
  };
}
```

`programs.zsh.enable = true`はzshパッケージも導入するため、`home.packages = [ pkgs.zsh ];`を別途残す必要はない。

`dotDir = config.home.homeDirectory`は、zshの設定先をホームディレクトリへ明示的に固定する。この指定により、将来`xdg.enable = true`を有効にしても、主要な設定ファイルは`~/.zshrc`として維持される。

ここで作られる`~/.zshrc`はHome Managerが生成するファイルであり、直接編集するファイルではない。設定元は`modules/zsh.nix`で、複雑なzsh関数が増えた場合は後から`dot_config/zsh/*.zsh`へ分離し、`programs.zsh.initContent`を通して合成する。

各optionの定義は[Home Managerのzsh option一覧](https://nix-community.github.io/home-manager/options.html#opt-programs.zsh.enable)で確認できる。

この段階では、既存`.bashrc`の次の要素をまだ移植しない。

- mise初期化
- sheldonとble.sh
- 独自prompt
- `ghq-path`と`dev`関数
- tmux session名の変更
- Dev Container用処理

まずHome Manager標準の機能だけでzshが安定して起動することを確認する。

## 2. 新規ファイルをGitへ登録する

Flakeが`modules/zsh.nix`を入力として認識できるようにする。

```bash
git add modules/zsh.nix hosts/nixos.nix
```

すでに登録済みなら、この操作による問題はない。

## 3. switchせずにbuildする

最初にactivation packageだけをbuildする。

```bash
nix build '.#homeConfigurations."hwata@nixos".activationPackage'
```

成功したら、Home Managerが生成するファイルを確認する。

```bash
find result/home-files -maxdepth 3 -print
```

`result/home-files/.zshrc`が含まれていることを確認する。

```bash
ls -l result/home-files/.zshrc
```

`dotDir = config.home.homeDirectory`を指定しているため、この生成物がswitch時に`~/.zshrc`へ配置される。

buildだけではホームディレクトリのファイルは変更されない。

## 4. 現在のzsh関連ファイルを確認する

switch前に、衝突しそうな既存ファイルを確認する。

```bash
ls -la ~/.zshrc ~/.zprofile ~/.zshenv ~/.config/zsh 2>/dev/null
```

既存ファイルが存在しても、すぐに削除しない。Home Managerがswitch時に衝突を報告したら、内容と管理元を確認してから退避する。`force = true`は使用しない。

## 5. Home Manager構成を反映する

buildが成功し、衝突対象を確認したらswitchする。

```bash
home-manager switch --flake '.#hwata@nixos'
```

失敗した場合は、エラーメッセージに出たファイルを確認する。既存bashはこのStepの管理対象ではないため、現在開いているshellはそのまま利用できる。

成功したら、`~/.zshrc`がHome Managerの生成物へのsymlinkになったことを確認する。

```bash
ls -l ~/.zshrc
readlink -f ~/.zshrc
```

`/nix/store/`以下を指していれば、`~/.zshrc`の所有権がHome Managerへ移った状態である。以後は`~/.zshrc`を直接編集せず、`modules/zsh.nix`を変更してswitchする。

## 6. bashからzshを手動起動する

現在のbashを終了せず、その内側でzshを起動する。

```bash
zsh
```

確認する。

```zsh
echo $ZSH_VERSION
command -v zsh
ps -p $$ -o comm=
```

`$SHELL`はログインシェルを表すため、この時点ではbashのパスが表示されても正常である。

```zsh
echo $SHELL
```

zshからbashへ戻るには次を実行する。

```zsh
exit
```

端末を閉じる必要はない。

## 7. 対話機能をsmoke testする

新しくzshを起動し、次を手動で確認する。

### 補完

途中まで入力して`Tab`を押す。

```zsh
git sta<Tab>
```

### 履歴共有

二つの端末でzshを起動する。片方で適当なコマンドを実行し、もう片方で履歴検索して表示されるか確認する。

```zsh
echo zsh-history-test
```

### Autosuggestion

一度実行したコマンドの先頭を入力し、候補が薄く表示されるか確認する。右矢印などで候補を受け入れられることも確認する。

### Syntax highlighting

存在するコマンドと存在しないコマンドを入力し、表示色が変わるか確認する。

```zsh
git
command-that-does-not-exist
```

実行する必要はない。

### vi keymap

コマンドラインへ文字を入力し、`Esc`を押してから`h`、`l`、`0`、`$`などで移動できることを確認する。`i`でinsert modeへ戻る。

### `Ctrl-C`

insert modeとnormal modeの両方で`Ctrl-C`を押し、現在の入力を中断して新しいpromptへ戻れるか確認する。長時間コマンドも中断できることを確認する。

```zsh
sleep 30
```

`Ctrl-C`の挙動に問題がある場合は、この時点ではログインシェルへ切り替えず、症状とkeymapを記録する。

### Alias

```zsh
alias ll
alias gs
```

実際に`ll`と`gs`も実行する。

## 8. fzfのzsh連携を追加する

最小のzshが正常に動いた後で、`modules/zsh.nix`のトップレベルへ次を追加する。

```nix
programs.fzf = {
  enable = true;
  enableZshIntegration = true;
};
```

全体は次の形になる。

```nix
{ config, ... }:

{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = true;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    defaultKeymap = "viins";

    history = {
      size = 100000;
      save = 100000;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    shellAliases = {
      ll = "ls -alF";
      la = "ls -A";
      lla = "ls -la";
      gs = "git status";
      c = "clear";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
```

再度buildしてからswitchする。

```bash
git add modules/zsh.nix
nix build '.#homeConfigurations."hwata@nixos".activationPackage'
home-manager switch --flake '.#hwata@nixos'
```

新しいzshを起動して`Ctrl-R`による履歴検索などを確認する。

```bash
zsh
```

既存 `.bashrc` の次の処理は、これでzsh側へ直接移植する必要がなくなる。

```bash
eval "$(fzf --bash)"
```

## 9. 変更を確認してcommitする

```bash
git diff -- modules/zsh.nix hosts/nixos.nix
git diff --cached -- modules/zsh.nix hosts/nixos.nix
git status
```

期待どおりならcommitする。

```bash
git add modules/zsh.nix hosts/nixos.nix
git commit -m "Manage zsh with Home Manager"
```

## ログインシェルの変更は次のStepへ送る

このStepが完了しても、まだ`chsh`は実行しない。

ログインシェルはHome Managerのユーザー設定ではなく、OS側のアカウント設定として扱う。

- NixOS: NixOS system configurationでzshとユーザーのshellを設定する
- Ubuntu: OS側のzshを導入して`chsh`する
- macOS: 標準の`/bin/zsh`を利用する

Home Managerは、各OSで起動されたzshへ共通設定を提供する。

## 完了条件

- `nix build`と`home-manager switch`が成功する
- `~/.zshrc`がHome Manager管理のsymlinkになっている
- bashから`zsh`を手動起動できる
- 補完、履歴共有、autosuggestion、syntax highlightingが動く
- vi keymapと`Ctrl-C`が期待どおり動く
- fzfのzsh連携が動く
- `exit`で既存bashへ安全に戻れる
- ログインシェルと既存bash設定はまだ変更されていない

完了後は、ログインシェルを変更する前に、既存`.bashrc`から本当に必要な関数、環境変数、mise連携を一項目ずつzsh側へ移す。
