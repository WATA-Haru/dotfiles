# Home Manager Step 9: Git設定とidentityを分離する

## この手順のゴール

chezmoiが生成している`~/.gitconfig`をHome Managerへ移し、Git本体と公開可能な設定をNixで管理する。一方、氏名とメールアドレスはGit管理やNix storeへ入れず、端末上のローカルファイルへ分離する。

このStepでは次の状態を目指す。

```text
Home Managerが管理
  Git package
  ~/.config/git/config
  identityファイルを読み込むinclude設定

端末ごとに手動で管理
  ~/.config/git/identity
  user.name
  user.email
```

完了時のリポジトリ構造は次のようになる。

```text
projects/dotfiles/
├── hosts/
│   ├── common.nix
│   └── nixos.nix
└── modules/
    ├── common.nix
    ├── git.nix
    └── ...
```

秘密鍵、credential helperのtoken、アクセストークンはこのGit identityファイルにも書かない。それらは別のcredential storeで管理する。

## 1. Step 8の完了を確認する

現在の差分と直近のcommitを確認する。

```zsh
git status
git log --oneline -5
```

Step 8の実装がcommit済みであることを確認する。このStepとは無関係な差分がある場合は、内容を把握したまま作業し、まとめてstageしない。

Home Managerの現在の構成もbuildしておく。

```zsh
nix build '.#homeConfigurations."hwata@nixos".activationPackage'
```

## 2. 現在のGit設定の管理元を確認する

まず、Gitが読み込んでいるglobal設定のkeyと出所を確認する。

```zsh
git config --global --show-origin --name-only --list
```

現在のchezmoi templateも確認する。

```zsh
sed -n '1,160p' home/dot_gitconfig.tmpl
sed -n '1,160p' home/.chezmoi.toml.tmpl
```

現在のtemplateが管理している実質的な値は次の二つである。

```text
user.name
user.email
```

実際の値は端末上で次のように確認できる。

```zsh
git config --global --get user.name
git config --global --get user.email
```

値をドキュメント、issue、terminal logへ貼り付けない。

## 3. identityの管理境界を決める

Git identityはcredentialではないが、氏名や所属メールアドレスは端末や所属によって変わる。このStepではFlakeへ値を渡さず、Git自身のinclude機能を使う。

Home Managerが生成する設定には次だけを書く。

```gitconfig
[include]
    path = ~/.config/git/identity
```

実際のidentityは、リポジトリ外の次のファイルへ置く。

```text
~/.config/git/identity
```

この方法では、identityの値がGit repositoryにもNix storeにもコピーされない。新しい端末ではHome Managerのswitch前にidentityファイルを用意する。

## 4. ローカルidentityファイルを作る

配置先を作る。

```zsh
mkdir -p ~/.config/git
```

すでに同名ファイルが存在する場合は上書きせず、内容と管理元を確認する。

```zsh
ls -l ~/.config/git/identity
```

存在しない場合は、permissionを限定して作成する。

```zsh
install -m 600 /dev/null ~/.config/git/identity
```

editorで次の形式を記述する。

```gitconfig
[user]
    name = YOUR NAME
    email = YOUR EMAIL
```

permissionを確認する。

```zsh
stat -c '%a %n' ~/.config/git/identity
```

`600`になっていればよい。

identityファイルは、このdotfiles repositoryへ追加しない。

```zsh
git status --short
```

`~/.config/git/identity`はrepositoryの外にあるため、statusへ表示されない。

## 5. Git用Home Manager moduleを作る

`modules/git.nix`を作る。

```nix
{ ... }:

{
  programs.git = {
    enable = true;

    includes = [
      {
        path = "~/.config/git/identity";
      }
    ];
  };
}
```

`programs.git.enable`はGit packageをユーザー環境へ導入し、`$XDG_CONFIG_HOME/git/config`を生成する。

氏名とメールアドレスを次のようにNixへ直接書かない。

```nix
# この構成では使用しない。
programs.git.settings.user = {
  name = "YOUR NAME";
  email = "YOUR EMAIL";
};
```

Nix式へ書いた値はFlakeの入力としてNix storeへコピーされるためである。

一般設定を今後追加する場合は、公開して問題ない値だけを`settings`へ置く。

```nix
programs.git.settings = {
  init.defaultBranch = "main";
};
```

この例は追加方法の説明であり、このStepでは既存設定にない値を勝手に追加しない。

## 6. 共通hostからGit moduleを読み込む

`hosts/common.nix`の`imports`へ`git.nix`を追加する。

```nix
{
  imports = [
    ../modules/cli.nix
    ../modules/common.nix
    ../modules/git.nix
    ../modules/neovim.nix
    ../modules/zsh.nix
    ../modules/tmux.nix
  ];

  programs.home-manager.enable = true;
}
```

`hosts/nixos.nix`にはidentityを書かない。host moduleもFlakeの一部であり、Nix storeへコピーされるためである。

## 7. 新しいmoduleをstageする

Flakeが新規ファイルを参照できるようにstageする。

```zsh
git add modules/git.nix hosts/common.nix
```

確認する。

```zsh
git status --short
git diff --cached --stat
```

`~/.config/git/identity`が含まれていないことを確認する。

## 8. switchせずにbuildする

```zsh
nix build '.#homeConfigurations."hwata@nixos".activationPackage'
```

Home Managerが生成するGit設定を確認する。

```zsh
sed -n '1,160p' result/home-files/.config/git/config
```

概ね次の内容になっていればよい。

```gitconfig
[include]
    path = ~/.config/git/identity
```

次を確認する。

- include先のpathだけが含まれている
- 実際の氏名とメールアドレスが含まれていない
- `user.name`と`user.email`がNixの生成物へ直接書かれていない

Home Managerの評価結果からincludeを確認することもできる。

```zsh
nix eval --json \
  '.#homeConfigurations."hwata@nixos".config.programs.git.includes'
```

## 9. 既存の`.gitconfig`を退避する

既存の`~/.gitconfig`にはchezmoiが生成したidentityが入っている。残したままにすると、新しいinclude先とidentityの管理元が重複する。

内容がローカルidentityファイルへ転記済みであることを確認してから、回復可能な名前へ移動する。末尾の日付は作業日に置き換える。

```zsh
mv ~/.gitconfig ~/.gitconfig.chezmoi-backup-YYYYMMDD
```

確認する。

```zsh
test -f ~/.gitconfig.chezmoi-backup-YYYYMMDD
test ! -e ~/.gitconfig
```

backupは新しいGit設定の確認が終わっても、すぐには削除しない。

## 10. Home Managerをswitchする

```zsh
home-manager switch --flake '.#hwata@nixos'
```

配置結果を確認する。

```zsh
type -a git
git --version
ls -l ~/.config/git/config
readlink -f ~/.config/git/config
```

`~/.config/git/config`がNix store上の生成ファイルを指していればよい。`~/.config/git/identity`は通常ファイルのまま残る。

## 11. 有効な設定と出所を確認する

Gitが読み込んでいるglobal設定を確認する。

```zsh
git config --global --includes --show-origin \
  --get-regexp '^user\.(name|email)$'
```

`user.name`と`user.email`の出所が`~/.config/git/identity`になっていればよい。同じkeyがbackupや別ファイルから重複して表示される場合は、残っているglobal configを調べる。

`git config`は、通常の設定検索ではincludeを辿る。一方、`--global`や`--file`で特定の設定ファイルを指定した場合はinclude展開が既定で無効になるため、ここでは`--includes`を明示する。

include自体の出所も確認する。

```zsh
git config --global --show-origin --get-regexp '^include\.path$'
```

Home Managerが生成した`~/.config/git/config`からidentityをincludeしていればよい。

Git repository内ではlocal設定がglobal設定を上書きできる。確認には`--show-origin`と`--show-scope`を利用できる。

```zsh
git config --includes --show-origin --show-scope --list
```

## 12. Gitの基本動作をsmoke testする

一時directoryを作り、既存repositoryへ影響を与えずに確認する。

```zsh
git_test_dir="$(mktemp -d)"
git -C "$git_test_dir" init
git -C "$git_test_dir" var GIT_AUTHOR_IDENT
git -C "$git_test_dir" var GIT_COMMITTER_IDENT
```

氏名とメールアドレスが期待どおり表示されればよい。

空のcommitまで確認する場合は、一時repository内だけで実行する。

```zsh
git -C "$git_test_dir" commit --allow-empty -m "Test Home Manager Git configuration"
git -C "$git_test_dir" log -1 --format=fuller
```

確認後、一時directoryは不要になる。削除する場合は、変数の値が`/tmp`配下の意図したdirectoryであることを先に確認する。

```zsh
printf '%s\n' "$git_test_dir"
```

この手順書では自動削除しない。必要なら作業後に明示的に削除する。

## 13. chezmoiのGit sourceを削除する

Home Manager版Gitとローカルidentityが正常に動くことを確認した後、chezmoiのsourceをGit管理から削除する。

```zsh
git rm home/dot_gitconfig.tmpl
```

`home/.chezmoi.toml.tmpl`にあるnameとemailのpromptは、Git templateだけが使用していた。ほかのtemplateから参照されていないことを確認する。

```zsh
rg -n '\.name|\.email' home
```

参照が残っていなければ、このprompt templateも不要になる。

```zsh
git rm home/.chezmoi.toml.tmpl
```

既存端末のchezmoi設定ファイルやbackupは、この操作では削除されない。

`.chezmoiignore`への追加は行わない。sourceを残したまま一時的に適用対象から除外するのではなく、Git設定の所有権をHome Managerへ移すためである。

ただし、chezmoiが現在参照しているsource directoryがこのrepositoryとは別にある場合、`git rm`だけでは実際のsource stateは変わらない。確認する。

```zsh
chezmoi source-path
chezmoi managed ~/.gitconfig
```

`.gitconfig`が表示され、chezmoiをすぐにはアンインストールしない場合は、管理対象から外す。

```zsh
chezmoi forget --dry-run --verbose ~/.gitconfig
chezmoi forget ~/.gitconfig
```

管理対象から外れたことを確認する場合は次を実行する。

```zsh
chezmoi managed ~/.gitconfig
```

何も表示されなければよい。

chezmoiをこの場でアンインストールし、それまで`chezmoi apply`を実行しない場合は`forget`を省略してもよい。

## 14. 変更を確認してcommitする

```zsh
git status
git diff --stat
git diff --cached --stat
git diff
git diff --cached
```

特に次を確認する。

- `modules/git.nix`が追加されている
- `hosts/common.nix`がGit moduleをimportしている
- `home/dot_gitconfig.tmpl`が削除されている
- 不要になった`home/.chezmoi.toml.tmpl`が削除されている
- 氏名とメールアドレスが差分に含まれていない
- `~/.config/git/identity`がGit管理へ入っていない

問題なければcommitする。

```zsh
git add \
  docs/home-manager-migration-plan.md \
  docs/home-manager-step8-tmux.md \
  docs/home-manager-step9-git.md \
  hosts/common.nix \
  modules/git.nix

git commit -m "Manage Git with Home Manager"
```

`git rm`したファイルはすでにstageされている。commit前に`git diff --cached`で削除対象を再確認する。

## 問題があった場合の戻し方

Home Manager版Gitを外す場合は、`hosts/common.nix`から`../modules/git.nix`のimportを外してbuildとswitchを行う。

Home Managerが生成した`~/.config/git/config`がなくなったことを確認してから、旧設定を戻す。末尾の日付は実際のbackup名へ置き換える。

```zsh
mv ~/.gitconfig.chezmoi-backup-YYYYMMDD ~/.gitconfig
```

既存の`~/.gitconfig`を上書きしない。

repository内のchezmoi templateは、commit前なら`git restore --staged`で削除のstageを外してから戻せる。commit後は通常のrevertまたは履歴から復元する。

## このStepではまだ行わないこと

- credentialやaccess tokenの管理
- commit signingの設定
- 仕事用と個人用identityのdirectory別切り替え
- Git aliasの追加
- delta、difftasticなどのdiff tool選定
- ghq、gwq、worktree workflowの変更
- jujutsuの設定
- backupファイルの削除

まずGit本体、公開設定、端末固有identityの管理境界を明確にする。

## 完了条件

- Git本体が`programs.git`から導入されている
- `~/.config/git/config`がHome Manager管理になっている
- Home ManagerのGit設定が`~/.config/git/identity`をincludeしている
- 氏名とメールアドレスがrepositoryとNix storeの生成設定に含まれていない
- `user.name`と`user.email`の出所がローカルidentityファイルになっている
- 一時repositoryでauthorとcommitterのidentityを取得できる
- chezmoiが`~/.gitconfig`を管理していない
- 旧`~/.gitconfig`が回復用backupとして残っている

Step 9完了後は、[`home-manager-step10-ghq-retire-chezmoi.md`](./home-manager-step10-ghq-retire-chezmoi.md)へ進み、ghq workflowを確認してからchezmoiを通常運用から撤去する。
