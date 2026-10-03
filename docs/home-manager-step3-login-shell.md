# Home Manager Step 3: zshをログインシェルにする

## この手順のゴール

Step 2でHome Manager管理のzshと`~/.zshrc`を安全に試せるようになった。このStepでは、NixOS側のユーザー設定でzshを正式なログインシェルにする。

完了時には、新しいSSH接続が最初からzshで起動する。一方、bashと既存`.bashrc`はまだ削除せず、問題発生時の退避経路として残す。

## Home Managerだけでは変更しない理由

Home Managerが担当するのは、zsh本体をユーザー環境へ追加し、`~/.zshrc`などを生成することである。

ログインシェルは`/etc/passwd`相当のOSユーザー情報であり、NixOSではNixOS system configurationが管理する。責務を次のように分ける。

| 対象 | 管理元 |
| --- | --- |
| zshをログインシェルとして許可する | NixOS |
| `hwata`のログインシェルをzshにする | NixOS |
| `~/.zshrc`、補完、履歴、alias、fzf連携 | Home Manager |

現在のログインシェルは次で確認できる。

```bash
getent passwd hwata
```

変更前は末尾が次のようになっている。

```text
/run/current-system/sw/bin/bash
```

## 1. Home Manager側が正常なことを再確認する

ログインシェルを変更する前に、dotfilesリポジトリでHome Manager構成をbuildする。

```bash
cd ~/wata-haru-vault/projects/dotfiles
nix build '.#homeConfigurations."hwata@nixos".activationPackage'
```

反映済みのzshをbashから手動起動し、最低限の確認をする。

```bash
zsh
echo $ZSH_VERSION
ls -l ~/.zshrc
exit
```

ここでzshの起動に失敗する場合は、ログインシェルを変更せずStep 2へ戻る。

## 2. 現在のNixOS設定を確認する

現在のNixOS設定では、ユーザーはおおむね次のように定義されている。

```nix
users.users.hwata = {
  isNormalUser = true;
  extraGroups = [ "wheel" "networkmanager" ];
};
```

編集前に対象箇所を確認する。

```bash
sed -n '120,150p' /etc/nixos/configuration.nix
```

NixOS設定はこのdotfilesリポジトリの管理外である。Step 3では`/etc/nixos/configuration.nix`を直接変更するが、将来NixOS system configurationを別リポジトリへ移す場合は、同じ設定をそちらへ移す。

## 3. NixOSでzshを有効にする

`/etc/nixos/configuration.nix`を`sudoedit`などで編集する。

```bash
sudoedit /etc/nixos/configuration.nix
```

トップレベルへ次を追加する。

```nix
programs.zsh.enable = true;
```

既存の`users.users.hwata`へ`shell`を追加する。

```nix
users.users.hwata = {
  isNormalUser = true;
  extraGroups = [ "wheel" "networkmanager" ];
  shell = pkgs.zsh;
};
```

全ユーザーのデフォルトをzshへ変える`users.defaultUserShell`ではなく、まず`hwata`だけを変更する。

Home Managerにも`programs.zsh.enable = true`があるが、重複ではない。

- NixOSの`programs.zsh.enable`: zshをOS上の対話shellとして構成する
- Home Managerの`programs.zsh.enable`: ユーザー用のzshと設定ファイルを管理する

## 4. NixOS構成をbuildする

まだ現在のシステムへ反映せず、最初にbuildだけ行う。

```bash
sudo nixos-rebuild build
```

エラーが出た場合は反映されていないため、Nix式を修正して再度buildする。

## 5. 現在のSSH接続を残してtestする

ログインシェル変更では、現在のSSH接続を閉じないことが重要である。問題が起きた場合に修正できるよう、現在のbashセッションを残したまま実行する。

```bash
sudo nixos-rebuild test
```

`test`は構成を現在のシステムへ一時的に反映するが、次回bootの既定generationにはしない。深刻な問題が起きても、再起動すれば以前のboot構成へ戻せる。

現在のセッションでユーザー情報を確認する。

```bash
getent passwd hwata
```

末尾がzshになっていることを確認する。Nix store内のパスまたはNixOSが管理するzshのパスが表示されればよい。

## 6. 別のSSH接続で確認する

現在の接続は残したまま、Ubuntu端末などから新しいSSH接続を開く。

```bash
ssh hwata@<NixOSのホスト名またはIPアドレス>
```

新しい接続で確認する。

```zsh
ps -p $$ -o comm=
echo $SHELL
echo $ZSH_VERSION
ls -l ~/.zshrc
readlink -f ~/.zshrc
```

さらにStep 2のsmoke testを短く繰り返す。

```zsh
gs
ll
```

- `Tab`補完が動く
- autosuggestionとsyntax highlightingが動く
- `Ctrl-R`でfzf履歴検索が動く
- `Esc`後のvi keymapが動く
- `Ctrl-C`で入力や`sleep 30`を中断できる
- `nix`、`home-manager`、`nvim`、`tmux`など普段使うコマンドが見つかる

すべて確認できるまで、元のSSH接続を閉じない。

## 7. 問題があった場合

新しいSSH接続が開けない、zshが即座に終了する、必要なコマンドが`PATH`にない、といった問題があれば、残してある元の接続から設定を戻す。

`users.users.hwata.shell = pkgs.zsh;`を削除し、必要なら`programs.zsh.enable = true;`も削除してから再適用する。

```bash
sudo nixos-rebuild test
```

`test`した構成から戻れない場合は再起動すると、まだ`switch`していない以前のboot構成へ戻る。

Home Manager側だけに問題がある場合は、bashを明示的に起動して修正できる。

```zsh
/run/current-system/sw/bin/bash
```

このStepではbashと`.bashrc`を削除していないため、退避経路として利用できる。

## 8. 正常なら次回bootへ反映する

別SSH接続で問題がないことを確認できたら、NixOS構成を正式にswitchする。

```bash
sudo nixos-rebuild switch
```

もう一度、別の新しいSSH接続でzshが起動することを確認する。

```zsh
getent passwd hwata
ps -p $$ -o comm=
echo $SHELL
```

## 9. Home Managerとの境界を確認する

ログインシェルを切り替えた後も、zsh設定を変更するときは`/etc/nixos/configuration.nix`ではなく、dotfilesリポジトリの`modules/zsh.nix`を編集する。

```bash
cd ~/wata-haru-vault/projects/dotfiles
nvim modules/zsh.nix
nix build '.#homeConfigurations."hwata@nixos".activationPackage'
home-manager switch --flake '.#hwata@nixos'
```

NixOS側を再buildする必要があるのは、ログインシェル本体やOSユーザー設定を変える場合だけである。

## UbuntuとmacOSでの違い

このStepの具体的な操作はNixOS専用である。共有する`modules/zsh.nix`はそのまま再利用できるが、ログインシェルの指定方法はOSごとに異なる。

- Ubuntu: OS側でzshを導入し、`chsh`でOS版zshを選ぶ
- macOS: 標準の`/bin/zsh`をログインシェルとして利用する
- NixOS: `programs.zsh.enable`と`users.users.<name>.shell`をsystem configurationへ書く

ログインシェルのパスをHome Manager profileやバージョン付きNix storeパスへ手作業で設定しない。OSが管理する安定したshell設定を使い、Home Managerは共通の`~/.zshrc`を担当する。

## このStepではまだ行わないこと

- 既存`.bashrc`、`.blerc`、bash本体の削除
- miseの移行または削除
- `ghq-path`、`dev`など独自関数の移植
- promptの作り込み
- Neovim、tmux、Git設定の移行

これらをログインシェル切り替えと同時に行うと、問題発生時の原因が分かりにくくなる。まず素のzsh環境を日常的に使える状態へする。

## 完了条件

- `sudo nixos-rebuild build`が成功する
- `sudo nixos-rebuild test`後に別SSH接続を開ける
- 新しい接続でzshがログインシェルとして起動する
- Home Manager管理の`~/.zshrc`が読み込まれる
- 補完、履歴、fzf、vi keymap、`Ctrl-C`が動く
- 普段使うCLIへ`PATH`が通っている
- 確認後に`sudo nixos-rebuild switch`が成功する
- bashと既存bash設定が退避経路として残っている

Step 3完了後は、既存bash設定から必要な環境変数と独自関数だけをzshへ移し、その依存コマンドもHome Manager管理へ移す。
