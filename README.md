# dotfiles

## Nix command一覧

NixOSとHome Managerのbuild、反映、rollbackで使うcommandは[Nix command cheat sheet](./docs/nix-commands.md)にまとめている。

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

## NixOSへのSSH接続方針

NixOSのTCP 22をpublic Internetへ直接公開しない。接続元の場所によって、次の二つの経路を使い分ける。

| 接続元 | 接続先 | 経路 |
| --- | --- | --- |
| 自宅LAN | NixOSのprivate IPv4 address | LAN内で直接TCP 22へ接続する |
| 自宅以外 | `nixos.tail7863cc.ts.net` | 同じtailnetへ参加し、Tailscale経由でTCP 22へ接続する |

どちらもNixOSのOpenSSH serverを利用する。Tailscale SSHは使用せず、Tailscaleは自宅以外からNixOSへ到達するためのprivate networkとして使用する。

NixOS側では次を維持する。

- password authenticationとkeyboard-interactive authenticationを無効にする
- root loginを無効にする
- login可能なuserを`hwata`へ限定する
- 自宅subnetとTailscale interfaceからのTCP 22だけをfirewallで許可する
- routerでTCP 22をport forwardingしない
- public keyだけを[`hosts/nixos/system/ssh.nix`](./hosts/nixos/system/ssh.nix)で管理する
- private keyはこのrepositoryやNix storeへ保存しない

Tailscale serviceは[`hosts/nixos/system/tailscale.nix`](./hosts/nixos/system/tailscale.nix)で管理する。

### Client用SSH keyを作成する

```zsh
ssh-keygen \
  -t ed25519 \
  -a 100 \
  -f ~/.ssh/laptop_to_nixos_ed25519 \
  -C 'laptop-to-nixos'
```

生成される二つのfileは役割が異なる。

```text
~/.ssh/laptop_to_nixos_ed25519       private key: clientの外へ出さない
~/.ssh/laptop_to_nixos_ed25519.pub   public key: NixOSへ登録する
```

permissionを確認する。

```zsh
chmod 600 ~/.ssh/laptop_to_nixos_ed25519
chmod 644 ~/.ssh/laptop_to_nixos_ed25519.pub
```

public keyを確認する。

```zsh
cat ~/.ssh/laptop_to_nixos_ed25519.pub
```

表示されたpublic key一行全体を、NixOS側の`users.users.hwata.openssh.authorizedKeys.keys`へ追加する。private keyの内容は追加しない。

最初はpassword loginを無効化する前にpublic keyを追加し、NixOSへ反映する。
hostで実行する。

```zsh
sudo nixos-rebuild switch --flake '.#nixos'
```

別terminalからpublic key loginに成功したことを確認した後、password authenticationを無効化する。設定変更中は、確認済みのSSH connectionまたはNixOSのlocal consoleを閉じない。

### ClientのSSH configへ登録する

`~/.ssh/config`がなければ作成し、permissionを限定する。既存fileは上書きしない。

```zsh
touch ~/.ssh/config
chmod 600 ~/.ssh/config
```

次を追加する。`192.168.0.24`は、routerでNixOSへ予約した実際のLAN addressへ置き換える。

```sshconfig
Host nixos-home
  HostName 192.168.0.24
  User hwata
  IdentityFile ~/.ssh/laptop_to_nixos_ed25519
  IdentitiesOnly yes

Host nixos-tail
  HostName nixos.tail7863cc.ts.net
  User hwata
  IdentityFile ~/.ssh/laptop_to_nixos_ed25519
  IdentitiesOnly yes
```

passphraseを設定したkeyをSSH agentへ登録する場合は、次を実行する。agentの起動と永続化方法はclient OSに任せる。

```zsh
ssh-add ~/.ssh/laptop_to_nixos_ed25519
ssh-add -l
```

### 接続

自宅LAN

```zsh
ssh nixos-home
```

自宅以外

```zsh
ssh nixos-tail
```

両方の接続でNixOS accountのpasswordを要求されず、登録したpublic keyでloginできればよい。keyのpassphrase入力はNixOS accountのpassword authenticationとは別であり、必要ならSSH agentで保持する。

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
