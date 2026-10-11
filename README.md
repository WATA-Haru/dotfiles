# dotfiles

## Home Managerへの移行

開発環境とdotfilesをchezmoiからNix + Home Managerへ段階的に移行する。

- [Home Manager移行計画](./docs/home-manager-migration-plan.md)

## Git identityの準備

Home ManagerはGit本体と公開可能な設定を管理する。氏名とメールアドレスは端末ごとに異なるため、このrepositoryやNix storeへ入れず、ローカルファイルで管理する。

新しい端末では、初回の`home-manager switch`より前に配置先を作る。

```zsh
mkdir -p ~/.config/git
```

`~/.config/git/identity`がまだ存在しないことを確認する。

```zsh
test ! -e ~/.config/git/identity
```

存在しない場合だけ、permissionを限定した空ファイルを作る。

```zsh
install -m 600 /dev/null ~/.config/git/identity
```

editorで次の内容を記述する。

```gitconfig
[user]
    name = YOUR NAME
    email = YOUR GITHUB NOREPLY EMAIL
```

GitHubのnoreply addressを使う場合は、GitHubのメール設定画面に表示されるaddressを指定する。

保存後、permissionを`600`へ揃える。

```zsh
chmod 600 ~/.config/git/identity
stat -c '%a %n' ~/.config/git/identity
```

Home Managerを適用する。

```zsh
home-manager switch --flake '.#hwata@nixos'
```

identityの値と読み込み元を確認する。`--global`を指定した場合はinclude展開が既定で無効になるため、`--includes`も指定する。

```zsh
git config --global --includes --show-origin \
  --get-regexp '^user\.(name|email)$'
```

`user.name`と`user.email`の読み込み元が`~/.config/git/identity`になっていればよい。

```zsh
git var GIT_AUTHOR_IDENT
git var GIT_COMMITTER_IDENT
```

`~/.config/git/identity`はこのrepositoryへ追加しない。Gitの設定構造と詳しい移行手順は[Home Manager Step 9](./docs/home-manager-step9-git.md)を参照する。

## Credentialとsecretの管理

Git identityはcommitへ記録される公開情報であり、credentialではない。そのため、現在は`sops-nix`で暗号化せず、上記のローカルファイルで管理する。

API token、password、秘密鍵などのsecretをNix式へ平文で書かない。Nix式やFlakeの入力はNix storeへコピーされ、意図しないユーザーから読める可能性がある。

将来、静的なsecretをdotfilesと一緒に宣言的に配布する必要が生じた場合は、[sops-nix](https://github.com/Mic92/sops-nix)を候補とする。暗号化済みファイルだけをGitへ保存し、復号用の`age`またはGPG秘密鍵はrepositoryとNix storeの外で管理する。

GitHubやその他のサービスへ対話的にログインするcredentialは、credential manager、password manager、SSH agentなども含めて用途ごとに選ぶ。`sops-nix`の導入は、管理対象となるsecretと復号鍵のbootstrap方法を決めてから独立したStepとして行う。

## `ubuntu/`配下

## 環境作成方針

Ubuntu は普段使いが目的で、何もしなくても動く安定性を求める。
環境をDev Containers で積極的に隔離し、ホームディレクトリを汚さない。

具体的な手段
- Dev Containersで開発し、dotfilesもDev Contianersにcloneしてきて使う
- 環境変数にcredentialの情報を渡さず、one password cliでセキュアに管理する
- aptはバージョンの固定や`yaml`,`toml`管理ができないため極力使わない。代わりにaquaとmiseを併用して　`yaml`, `toml`ベースでCLIツールを管理する。

### Ubuntuを選んだ理由

このdotfilesの目的は安定して開発ができる環境を作ることだ。
そのため、OSはクセがなく安定しており、情報が得やすいUbuntuを選んだ。
検討段階ではすべてを管理できるNixやLinuxそのものに詳しくなれるArchも考えたが、これらは開発以外のことに多くの時間を取られそうだと感じたためメインのOSにはせず、趣味や空いた時間に触ることにした。

## snap, deb-getの混在とその理由

snapはinstallも削除も簡単で隔離もできるため、優先的に使う。
一方で、snap版で不具合が出るものはdeb-getを使ってdeb packagesからビルドする。

## WMを入れない理由

Windows Managerは興味はあるものの、
Window Keyと他のキーでの操作で足りているので入れなかった。

## Update and Upgrade

deb-get README: https://github.com/wimpysworld/deb-get

```bash
sudo apt update
sudp apt upgrade

sudo deb-get update
sudo deb-get upgrade
```
