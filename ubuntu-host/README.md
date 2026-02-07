## ここに書くこと

CLIだけで設定できず、ユーザが対話的に設定しなければいけない項目とその手順をまとめる

## 環境

Ubuntu Desktop 24.04.3 LTS

## 初期設定

インストーラーの支持に従い、`autoinstall.yaml`を用いて設定
`autoinstall.sample.yaml`を参照

参考
[autoinstall.yamlでUbuntu 24.04 LTSの初期設定を半自動化する](https://zenn.dev/bita/articles/3e75e55aefaa4c)

## ホームディレクトリ配下のディレクトリを英語化

日本語設定にしているとホームディレクトリ配下のディレクトリ名は「ドキュメント」、「ダウンロード」、「ミュージック」のようになっている。これを「Documents」、「Downloads」、「Music」のような英語のディレクトリ名に変更した。

(参考)
金子邦彦研究室 「Ubuntu: ユーザーディレクトリ名を標準の英語表記に変更する手順」
https://www.kkaneko.jp/tools/server/gnome_user_dirs.html

1. 以下のコマンドを実行
```bash
LANG=C LC_ALL=C xdg-user-dirs-gtk-update
```
2. ポップアップがでるので「Update Names」ボタンで更新
3. Ubuntuからログアウトして設定を反映
4. 再ログインすると再度ポップアップがでるので、古い名前のままにするを選択

## PCに画面をオフにしてディスプレイだけに画面を表示する

好みだが、外付けディスプレイを使うときにPCモニタをオフにしてディスプレイだけに画面を表示する。
GUIで設定する。

1. 「設定」＞「ディスプレイ」を開く。
2. 画面上部の「表示モード」で「拡張（Join Displays）」を選択。
3. ディスプレイのリストから 「Built-in Display（内蔵ディスプレイ）」を選択。
4. そのディスプレイのスイッチを 「オフ」 に切り替える。
5. 「適用」を押す。

## INFO: snap版で問題があったパッケージ
obsidian
- snap版は日本語入力が使えなかった
slack
- 毎回ログインを求められるようになったためdeb packageを使用

