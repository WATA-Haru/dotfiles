# dotfiles
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

