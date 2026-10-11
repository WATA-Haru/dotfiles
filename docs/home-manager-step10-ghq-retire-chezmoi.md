# Home Manager Step 10: ghq workflowを確定してchezmoiを撤去する

## この手順のゴール

すでにHome Managerから導入されているghqの設定場所をGit moduleへ集約し、repositoryの取得とfzfによる移動を確認する。その後、日常環境がchezmoiへ依存していないことを監査し、chezmoiをNixOSのsystem packageから外す。

このStepでは次を行う。

- ghq packageの宣言を`modules/common.nix`から`modules/git.nix`へ移す
- `ghq.root`をHome Manager管理のGit設定へ明示する
- wget、jujutsu、Codexのpackageを`modules/cli.nix`へ移す
- `ghq get`、`ghq list`、`dev`関数をsmoke testする
- 現在利用していないgwqとworktree workflowは移行しない
- chezmoiが管理していた残りのファイルを、削除対象とローカルで残す対象に分類する
- NixOSのsystem packagesからchezmoiと重複するghqを外す
- chezmoiのsourceとconfigは即削除せず、回復用に退避する

完了時の主要な構造は次のようになる。

```text
modules/
├── common.nix       ghqを含まない汎用package
├── git.nix          Git本体、Git設定、ghq package
└── zsh.nix          ghqを使う関数を読み込む

dot_config/zsh/
└── functions.zsh    ghq-pathとdev
```

chezmoiをアンインストールしても、chezmoiが過去に生成した通常ファイルは自動では削除されない。このStepではfcitx5やGhosttyなど未移行の設定を消さず、当面はローカルの未管理設定として残す。

## 1. Step 9までの変更を区切る

現在の差分と直近のcommitを確認する。

```zsh
git status
git log --oneline -5
```

Step 9のGit設定がcommit済みで、次が正常に表示されることを確認する。

```zsh
git config --global --includes --show-origin \
  --get-regexp '^user\.(name|email)$'
```

Home Manager構成もbuildしておく。

```zsh
nix build '.#homeConfigurations."hwata@nixos".activationPackage'
```

## 2. 現在のghq設定を確認する

実行ファイルの管理元とversionを確認する。

```zsh
type -a ghq
ghq --version
```

現在のrootを確認する。

```zsh
ghq root
git config --global --show-origin --get-regexp '^ghq\.root$'
```

現時点ではGit設定に`ghq.root`がなくても、ghqの既定値により`~/ghq`が表示される。このStepでは暗黙の既定値へ依存せず、Home Managerから同じ値を明示する。

登録済みrepositoryも確認する。

```zsh
ghq list
ghq list --full-path
```

何も表示されない場合は、`~/ghq`にまだrepositoryがないだけであり、エラーではない。

## 3. 既存のghq workflowを確認する

現在のzsh関数を読む。

```zsh
sed -n '1,160p' dot_config/zsh/functions.zsh
```

役割は次のとおり。

```text
ghq-path
  ghq list --full-pathの結果をfzfで選択する

dev
  選択したrepositoryへcdする
  tmux内ではsession名をrepository名へ変更する
```

gwqとGit worktreeは現在利用していないため、この関数へ追加しない。まず一つのrepositoryを一つのcloneとして扱う単純なworkflowを維持する。

## 4. ghqをGit moduleへ移す

ghqはGit repositoryを扱うCLIなので、packageの宣言を`modules/common.nix`から`modules/git.nix`へ移す。

`modules/common.nix`の`home.packages`から`ghq`を削除する。

```nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ripgrep
  ];
}
```

`modules/git.nix`で`pkgs`を引数に受け取り、ghq packageとrootを追加する。

```nix
{ pkgs, ... }:

{
  home.packages = [
    pkgs.ghq
  ];

  programs.git = {
    enable = true;

    includes = [
      {
        path = "~/.config/git/identity";
      }
    ];

    settings = {
      init.defaultBranch = "main";
      ghq.root = "~/ghq";
    };
  };
}
```

`ghq.root`は秘密情報ではなく、全端末で共有できるrepository配置規則なのでHome Manager管理にする。

### wget、jujutsu、CodexをCLI moduleへ追加する

これらは通常ユーザーとして日常的に使うCLIなので、`modules/cli.nix`の既存`home.packages`を次のlistへ変更する。`programs.bat`、`programs.fd`、`programs.yazi`はそのまま残す。

```nix
# packageだけを管理し、各CLIの認証情報には触れない。
home.packages = with pkgs; [
  codex
  gh
  jujutsu
  wget
];
```

packageをHome Managerへ移しても、CodexやGitHub CLIのlogin情報はNixで管理しない。このStepではjujutsuのpackageだけを移し、日常workflowやrepository設定はバックログのままにする。

## 5. 旧ghq・gwq設定を整理する

旧chezmoi sourceには、ghq rootだけを設定するファイルが残っている。

```zsh
sed -n '1,80p' home/dot_config/git/config
```

この値は`modules/git.nix`へ移したため、旧ファイルを削除する。

```zsh
git rm home/dot_config/git/config
```

gwqは現在利用しておらず、workflowも移行しない。設定内容を最後に確認する。

```zsh
sed -n '1,120p' home/dot_config/gwq/config.toml
```

不要であることを確認してから削除する。

```zsh
git rm home/dot_config/gwq/config.toml
```

Git履歴から復元できるため、使う可能性だけを理由にactiveな設定として残さない。

## 6. 変更をstageしてbuildする

```zsh
git add \
  modules/cli.nix \
  modules/common.nix \
  modules/git.nix
```

`git rm`した二つのファイルはすでにstageされている。差分を確認する。

```zsh
git status --short
git diff --cached
```

Home Manager構成をbuildする。

```zsh
nix build '.#homeConfigurations."hwata@nixos".activationPackage'
```

生成されたGit設定にghq rootが含まれることを確認する。

```zsh
rg -n 'ghq|root' result/home-files/.config/git/config
```

生成されたユーザー環境にghqが含まれることも確認する。

```zsh
result/home-path/bin/ghq --version
result/home-path/bin/wget --version | head -n 1
result/home-path/bin/jj --version
result/home-path/bin/codex --version
```

## 7. Home Managerをswitchする

```zsh
home-manager switch --flake '.#hwata@nixos'
```

新しいzshを起動し、管理元と設定を確認する。

```zsh
exec zsh
```

```zsh
type -a ghq
type -a wget
type -a jj
type -a codex
ghq --version
ghq root
git config --global --show-origin --get-regexp '^ghq\.root$'
```

期待するrootは次である。

```text
/home/hwata/ghq
```

Git設定の出所は、Home Managerが生成した`~/.config/git/config`になっていればよい。

## 8. repositoryをghqで取得する

日常利用するrepositoryを一つ選ぶ。すでに別の場所にある作業中repositoryを、テスト目的で移動しない。

SSHで取得する場合は次を使う。

```zsh
ghq get -p github.com/OWNER/REPOSITORY
```

HTTPSで取得する場合は`-p`を付けない。

```zsh
ghq get https://github.com/OWNER/REPOSITORY.git
```

clone先を確認する。

```zsh
ghq list
ghq list --full-path
```

概ね次の構造になる。

```text
~/ghq/github.com/OWNER/REPOSITORY
```

現在のdotfiles repositoryは`~/wata-haru-vault/projects/dotfiles`にあり、ghq rootの外にある。移動する必然性がなければ、そのまま維持する。

ghq 1.10以降の`migrate`で既存repositoryを移せるが、実行前に必ずdry-runする。

```zsh
ghq migrate --dry-run ~/wata-haru-vault/projects/dotfiles
```

このStepではdotfiles repositoryを実際には移動しない。

## 9. fzfと`dev`関数をsmoke testする

関数が読み込まれていることを確認する。

```zsh
type ghq-path
type dev
```

`ghq-path`を実行し、この手順のSection 8で取得したrepositoryをfzfから選べることを確認する。

```zsh
ghq-path
```

`Esc`でキャンセルした場合、shellが終了せず、現在のdirectoryも変わらないことを確認する。

```zsh
pwd
dev
pwd
```

次にrepositoryを選び、移動先を確認する。

```zsh
dev
pwd
git remote -v
```

tmux内でも`dev`を実行する。

```zsh
tmux display-message -p '#S'
dev
tmux display-message -p '#S'
```

選択後のsession名がrepository名へ変わればよい。

## 10. chezmoi撤去前の管理対象を記録する

chezmoiを削除する前に、現在のsource directoryと管理対象を記録する。

```zsh
chezmoi source-path
chezmoi managed
```

この環境では、Home Managerへ移行していない次の設定が残っている可能性がある。

```text
~/.config/fcitx5
~/.config/ghostty
~/.vimrc
~/vscode-neovim
```

chezmoiをアンインストールしても、これらのdestination fileは残る。ただし以後は自動更新されず、再構築にも使われないローカル設定になる。

次は旧shellまたは廃止済みツールの設定なので、通常のzsh環境から参照されていないことを確認する。

```text
~/.bashrc
~/.blerc
~/.config/mise
~/.config/sheldon
~/.config/gwq
```

このStepではdestination fileを一括削除しない。削除はHome Managerと新しいzshだけで十分に作業できることを確認した後、個別に行う。

`~/.config/nix/nix.conf`にはFlakes設定が残っている。NixOS system configurationにも同じ設定があることを確認する。

```zsh
rg -n 'experimental-features|nix\.settings' /etc/nixos
sed -n '1,80p' ~/.config/nix/nix.conf
```

重複の解消もこのStepでは行わず、NixOS設定を正として後から整理する。

## 11. activeな構成がchezmoiへ依存しないことを確認する

Home Managerのactiveな入力を検索する。

```zsh
rg -n 'chezmoi' \
  flake.nix \
  hosts \
  modules \
  dot_config \
  apply.sh
```

何も表示されなければよい。docs、legacyな`home/`、過去のinstall scriptにchezmoiという文字が残っていても、Home Managerの評価やswitchには影響しない。

最後にもう一度buildとswitchを行う。

```zsh
nix build '.#homeConfigurations."hwata@nixos".activationPackage'
home-manager switch --flake '.#hwata@nixos'
```

新しいzsh、Git、Neovim、tmux、ghqが動くことを確認する。

```zsh
zsh --version
git --version
nvim --version | head -n 1
tmux -V
ghq --version
wget --version | head -n 1
jj --version
codex --version
```

## 12. NixOSのsystem packagesから重複packageを外す

現在のchezmoiと移行前のCLIは、NixOSの次のファイルから導入されている。

```text
/etc/nixos/daily-use-packages.nix
```

現在の宣言を確認する。

```zsh
rg -n 'chezmoi|wget|jujutsu|codex|git|gh|ghq|fzf|tmux|sheldon' \
  /etc/nixos
```

Home Manager版のbuild、switch、smoke testが完了してから、`environment.systemPackages`から次を削除する。

```nix
chezmoi
codex
fzf
git
gh
ghq
jujutsu
sheldon
tmux
wget
```

chezmoiとsheldonは廃止対象であり、それ以外はHome Managerから引き続き導入される。

rootのlogin shellでもVimとNeovimを利用する方針なので、次はNixOS側へ残す。

```nix
vim
neovim
ghostty.terminfo
```

まずNixOS構成をbuildする。

```zsh
sudo nixos-rebuild build
```

成功したらswitchする。

```zsh
sudo nixos-rebuild switch
```

新しいzshから確認する。

```zsh
exec zsh
```

```zsh
command -v chezmoi
type -a ghq
type -a wget
type -a jj
type -a codex
```

`command -v chezmoi`が何も表示せず、ghq、wget、jj、codexが`~/.nix-profile/bin`から利用できればよい。

問題があれば、NixOSの一つ前のgenerationへ戻すか、`daily-use-packages.nix`へpackageを戻して再buildする。

## 13. chezmoiのsourceとconfigを退避する

chezmoi packageを外しても、sourceと内部stateは自動削除されない。すぐには削除せず、日付付きの名前へ変更する。末尾の日付は作業日に置き換える。

```zsh
mv ~/.local/share/chezmoi \
  ~/.local/share/chezmoi.retired-YYYYMMDD

mv ~/.config/chezmoi \
  ~/.config/chezmoi.retired-YYYYMMDD
```

この操作は回復可能であり、過去のsourceやstateを確認する余地を残す。

```zsh
test -d ~/.local/share/chezmoi.retired-YYYYMMDD
test -d ~/.config/chezmoi.retired-YYYYMMDD
```

退避directoryは、Home Managerだけで新しい端末を再構築できることを確認するまで削除しない。

## 14. repository側のlegacyを分類する

chezmoiを通常運用から外しても、このrepositoryには過去のsourceと導入scriptが残る。これらを一度に削除すると、未移行のfcitx5やGhostty設定まで失うため、このStepでは分類だけを行う。

```zsh
git ls-files 'home/**'
rg -n 'chezmoi' install README.md docs
```

分類は次のとおり。

| 分類 | 例 | 後続作業 |
| --- | --- | --- |
| Home Managerへ移行済み | Git、Neovim、tmux、zsh | 旧sourceを削除候補にする |
| 廃止済み | bash + ble.sh、mise、sheldon、gwq | 内容確認後に削除する |
| 未移行だが残す | fcitx5、Ghostty、VSCode Neovim、vimrc | `legacy/`へ隔離するか個別に移行する |
| 古いbootstrap | `install/host`、Dev Container用chezmoi処理 | 有効な情報を回収後に削除する |

repository内のlegacy整理は、runtimeのchezmoi撤去とは別のcommitにする。

## 15. 変更を確認してcommitする

```zsh
git status
git diff --stat
git diff --cached --stat
git diff
git diff --cached
```

特に次を確認する。

- ghq packageが`modules/git.nix`だけで宣言されている
- wget、jujutsu、Codexが`modules/cli.nix`で宣言されている
- `ghq.root`が`~/ghq`に固定されている
- `modules/common.nix`にghqが残っていない
- 旧`home/dot_config/git/config`が削除されている
- 未使用の`home/dot_config/gwq/config.toml`が削除されている
- gwqやworktreeの新しい設定を追加していない
- Home Managerのactiveな構成がchezmoiへ依存していない
- NixOSから重複packageを外した後もghq、wget、jj、codexを利用できる

問題なければrepository側の変更をcommitする。

```zsh
git add \
  docs/home-manager-migration-plan.md \
  docs/home-manager-step9-git.md \
  docs/home-manager-step10-ghq-retire-chezmoi.md \
  modules/cli.nix \
  modules/common.nix \
  modules/git.nix

git commit -m "Manage ghq with Home Manager"
```

NixOSの`/etc/nixos`が別のGit repositoryである場合、重複packageをsystem packagesから外した変更はそちらで別にcommitする。

## 問題があった場合の戻し方

ghq設定だけを戻す場合は、`modules/git.nix`からghq packageと`ghq.root`を外し、`modules/common.nix`へ`ghq`を戻してbuildとswitchを行う。

chezmoiや移行したCLIが再びsystem packageとして必要になった場合は、NixOSの`environment.systemPackages`へ必要なpackageだけを戻して`nixos-rebuild switch`する。chezmoiの場合は、退避したsourceとconfigも元の場所へ戻す。

```zsh
mv ~/.local/share/chezmoi.retired-YYYYMMDD \
  ~/.local/share/chezmoi

mv ~/.config/chezmoi.retired-YYYYMMDD \
  ~/.config/chezmoi
```

既存の同名directoryを上書きしない。

## このStepではまだ行わないこと

- gwqの再導入
- Git worktree workflowの構築
- jujutsuの日常workflow化
- Git diff/review toolの選定
- fcitx5、Ghostty、VSCode Neovim設定のHome Manager移行
- 旧bash、mise、sheldon設定の一括削除
- `install/host`全体の削除
- 退避したchezmoi source、state、backupの完全削除

## 完了条件

- ghqがHome Managerから導入されている
- `ghq root`が`~/ghq`を返す
- `ghq get`したrepositoryが`ghq list`へ表示される
- `dev`でrepositoryへ移動でき、キャンセルしても現在位置が変わらない
- tmux内の`dev`でsession名がrepository名へ変わる
- gwqとworktreeの設定を追加していない
- Home Managerのactiveな構成がchezmoiへ依存していない
- NixOSのsystem packagesにchezmoiとHome Manager管理CLIの重複がない
- wget、jj、codexがHome Manager profileから起動する
- `command -v chezmoi`が何も返さない
- 旧chezmoi sourceとconfigが回復可能な形で退避されている
- 未移行のdestination fileが誤って削除されていない

Step 10完了後は、chezmoiを使わずHome Managerを通常運用する。repository内に残る旧sourceとinstall scriptは、機能単位で`legacy/`へ隔離または削除する。
