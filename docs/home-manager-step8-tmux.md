# Home Manager Step 8: tmuxをHome Managerへ移行する

## この手順のゴール

chezmoiが生成しているtmux設定をHome Managerへ移し、tmux本体と設定の管理元を一つにする。

このStepでは次のことを行う。

- `hosts/nixos.nix`から共通のmodule選択を`hosts/common.nix`へ分離する
- tmux本体を`programs.tmux`で管理する
- tmux固有の設定を`dot_config/tmux/tmux.conf`へ置く
- Home Managerで表現できる標準optionは`modules/tmux.nix`へ置く
- `default-shell /bin/bash`を廃止し、login shellのzshを利用する
- tmux内の`TERM`を`tmux-256color`へ統一する
- 現在の端末でchezmoiによるtmux設定の管理を停止する

完了時の主要な構造は次のようになる。

```text
projects/dotfiles/
├── flake.nix
├── hosts/
│   ├── common.nix
│   └── nixos.nix
├── modules/
│   ├── cli.nix
│   ├── common.nix
│   ├── neovim.nix
│   ├── tmux.nix
│   └── zsh.nix
└── dot_config/
    └── tmux/
        └── tmux.conf
```

`hosts/common.nix`は、各hostで利用するHome Manager moduleの組み合わせを表す。一方、既存の`modules/common.nix`は共通packageを宣言する機能moduleである。同名でもdirectoryと役割が異なる。

tmux設定をすべてNixの文字列へ翻訳することはしない。Home Managerはpackageと標準optionを担当し、tmux固有の細かな設定はtmux.conf形式のまま維持する。

## 1. Step 7までの変更を区切る

現在の差分を確認する。

```zsh
git status
git diff
git diff --cached
```

Step 7までの変更が残っている場合は、内容を確認して先にcommitする。未確認の変更をまとめてstageしない。

現在、次のrenameだけを開始済みでも問題ない。

```text
home/dot_config/tmux/tmux.conf.tmpl -> dot_config/tmux/tmux.conf
```

この場合はそのファイルを移動先としてそのまま使用する。

## 2. 共通のhost構成を作る

最初にtmuxとは独立したリファクタリングとして、`hosts/nixos.nix`にある共通部分を`hosts/common.nix`へ移す。

この時点では`modules/tmux.nix`がまだ存在しないため、既存のmoduleだけをimportする。

`hosts/common.nix`を作る。

```nix
{
  imports = [
    ../modules/cli.nix
    ../modules/common.nix
    ../modules/neovim.nix
    ../modules/zsh.nix
  ];

  programs.home-manager.enable = true;
}
```

このファイルにはusername、home directory、CPU architectureを書かない。複数のhostで共有できる機能の選択だけを置く。

`hosts/nixos.nix`は次のようにする。

```nix
{
  imports = [
    ./common.nix
  ];

  home.username = "hwata";
  home.homeDirectory = "/home/hwata";
  home.stateVersion = "26.05";
}
```

`home.stateVersion`はHome Managerを最初に導入した値を維持する。NixpkgsやHome Managerを更新するたびに変更しない。

## 3. host構成のリファクタリングをbuildする

FlakeはGit管理対象のファイルだけを入力としてNix storeへコピーする。新規作成した`hosts/common.nix`をstageする。

```zsh
git add hosts/common.nix hosts/nixos.nix
```

tmuxを変更する前に、現在の構成が引き続きbuildできることを確認する。

```zsh
nix build '.#homeConfigurations."hwata@nixos".activationPackage'
```

このbuildが失敗した場合は、tmux移行へ進む前に`hosts/common.nix`と`hosts/nixos.nix`のimportsを見直す。

## 4. tmux設定を`dot_config`へ移す

すでに`dot_config/tmux/tmux.conf`まで移動している場合は、そのままStep 5へ進む。

まだ元のtemplateにある場合は、代わりに次を実行する。

```zsh
mkdir -p dot_config/tmux
git mv \
  home/dot_config/tmux/tmux.conf.tmpl \
  dot_config/tmux/tmux.conf
```

この時点では`~/.config/tmux/tmux.conf`は変化せず、実行中のtmux serverにも影響しない。

設定ファイルが一つだけの間は、一般的な`tmux.conf`という名前を使う。将来OS固有設定などへ分割する必要が生じた時点で、`common.conf`と追加ファイルに分ければよい。

## 5. `tmux.conf`を通常のtmux設定へ整理する

`dot_config/tmux/tmux.conf`を次の内容へ整理する。

```tmux
# Settings represented by Home Manager options live in modules/tmux.nix.

# Keep mouse wheel behavior while mouse itself is enabled by Home Manager.
bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'copy-mode -e'"

# Open windows and panes in the current pane's directory.
bind c new-window -c '#{pane_current_path}'
bind | split-window -h -c '#{pane_current_path}'
bind - split-window -v -c '#{pane_current_path}'

# Vim-style copy mode.
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi V send -X select-line
bind -T copy-mode-vi C-v send -X rectangle-toggle
bind -T copy-mode-vi y send -X copy-selection
bind -T copy-mode-vi Y send -X copy-line

# Status line.
set-option -g status-position top
set-option -g status-justify centre
set-option -g status-left-length 90
set-option -g status-right-length 90
set-option -g status-style "fg=color253,bold,bg=color104"
set-option -g status-left '#H:[#P]'
set-option -g status-interval 1

# Pane borders.
set-option -g pane-border-style "fg=colour248,bold"
set-option -g pane-active-border-style "fg=colour34,bold"

# Advertise RGB support for terminals used outside tmux.
set-option -as terminal-features ",xterm-256color:RGB"
set-option -as terminal-features ",xterm-ghostty:RGB"

# Allow tmux copy operations and `tmux load-buffer -w` to use OSC 52.
set-option -g set-clipboard on
```

元のtemplateから次を取り除く。

- chezmoiの`{{ if ... }}`などのtemplate構文
- `default-shell /bin/bash`
- `default-terminal`
- Home Managerの標準optionへ移す設定

同じoptionをtmux設定とNix moduleの両方へ残さず、最終値の管理場所を一つにする。

| 元のtmux設定 | 移動先 |
| --- | --- |
| `default-shell /bin/bash` | 削除。login shellのzshを使う |
| `default-terminal` | `programs.tmux.terminal` |
| `mode-keys vi` | `programs.tmux.keyMode` |
| `mouse on` | `programs.tmux.mouse` |
| prefix設定 | `programs.tmux.prefix` |
| pane移動・resize | `customPaneNavigationAndResize` |
| `base-index 1` | `programs.tmux.baseIndex` |
| `escape-time 0` | `programs.tmux.escapeTime` |
| `focus-events on` | `programs.tmux.focusEvents` |

## 6. tmux用Home Manager moduleを作る

`modules/tmux.nix`を作る。

```nix
{ ... }:

{
  programs.tmux = {
    enable = true;

    terminal = "tmux-256color";
    baseIndex = 1;
    keyMode = "vi";
    mouse = true;
    prefix = "C-f";
    escapeTime = 0;
    focusEvents = true;

    customPaneNavigationAndResize = true;
    resizeAmount = 5;

    # Keep the conventional /tmp/tmux-UID socket during this migration.
    secureSocket = false;

    extraConfig = builtins.readFile ../dot_config/tmux/tmux.conf;
  };
}
```

`builtins.readFile`はtmux設定を文字列として読み込み、その内容をHome Managerが生成するtmux.confへ追加する。

### `shell`を指定しない理由

`programs.tmux.shell`は設定しない。新しいtmux serverはユーザーのlogin shellを既定値として使う。

NixOSではStep 3でユーザーのlogin shellをzshへ変更済みである。絶対パスをtmux moduleへ重複して書かず、OS側のlogin shell設定を正とする。

確認する場合は次を実行する。

```zsh
getent passwd hwata
```

行末のshellがzshを指していればよい。

### `secureSocket = false`について

固定中のHome Managerは、tmux socketの場所を`$XDG_RUNTIME_DIR`へ変更する場合がある。現在のserverは`/tmp/tmux-UID`を使用しているため、初回移行と同時にsocketを変えると既存sessionが消えたように見える。

このStepでは上流tmux標準の場所を維持する。socketの場所を変更したい場合は、tmux移行後に独立した変更として検討する。

## 7. tmux packageの重複をなくす

`programs.tmux.enable = true`がtmux本体を導入するため、`modules/common.nix`の`home.packages`から`tmux`を削除する。

```nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ghq
    ripgrep
  ];
}
```

tmux本体と設定の宣言は`modules/tmux.nix`へ集約する。

## 8. 共通hostからtmux moduleを読み込む

`hosts/common.nix`の`imports`へ`tmux.nix`を追加する。

```nix
{
  imports = [
    ../modules/cli.nix
    ../modules/common.nix
    ../modules/neovim.nix
    ../modules/tmux.nix
    ../modules/zsh.nix
  ];

  programs.home-manager.enable = true;
}
```

`hosts/nixos.nix`には変更を加えない。NixOS hostは`./common.nix`を通してtmux moduleを利用する。

## 9. 新しいファイルをGitへ登録する

Flakeが新しいmoduleと移動後の設定ファイルを参照できるようにstageする。

```zsh
git add \
  hosts/common.nix \
  hosts/nixos.nix \
  modules/common.nix \
  modules/tmux.nix \
  dot_config/tmux/tmux.conf
```

確認する。

```zsh
git status --short
git diff --cached --stat
```

移動元は削除、移動先は追加またはrenameとして表示される。

## 10. switchせずにbuildする

まず現在利用中のNixOS構成が壊れていないことを確認する。

```zsh
nix build '.#homeConfigurations."hwata@nixos".activationPackage'
```

生成されたtmux設定を確認する。

```zsh
sed -n '1,280p' result/home-files/.config/tmux/tmux.conf
```

Home Managerが生成した標準optionと、`dot_config/tmux/tmux.conf`から取り込んだ設定が一つのファイルになっている。

重要な値を検索する。

```zsh
rg -n \
  'default-terminal|base-index|pane-base-index|mode-keys|mouse|prefix|escape-time|focus-events|set-clipboard|default-shell' \
  result/home-files/.config/tmux/tmux.conf
```

次を確認する。

- `default-terminal`が`tmux-256color`
- windowとpaneのindexが1から始まる
- key modeがvi
- mouseがon
- prefixが`C-f`
- `escape-time`が0
- `focus-events`がon
- `set-clipboard`がon
- `default-shell /bin/bash`が存在しない
- chezmoiのtemplate構文が存在しない

`extraConfig`だけを直接評価することもできる。

```zsh
nix eval --raw \
  '.#homeConfigurations."hwata@nixos".config.programs.tmux.extraConfig'
```

## 11. 隔離したtmux serverで構文を確認する

現在利用中のtmux serverへ触れず、`hm-step8`という別socketで生成設定を読み込む。

```zsh
TMUX= result/home-path/bin/tmux \
  -L hm-step8 \
  -f "$(readlink -f result/home-files/.config/tmux/tmux.conf)" \
  new-session -d -s smoke
```

設定値を確認する。

```zsh
TMUX= result/home-path/bin/tmux -L hm-step8 show-options -gv default-terminal
TMUX= result/home-path/bin/tmux -L hm-step8 show-options -gv default-shell
TMUX= result/home-path/bin/tmux -L hm-step8 show-options -gv prefix
TMUX= result/home-path/bin/tmux -L hm-step8 show-options -gv set-clipboard
TMUX= result/home-path/bin/tmux -L hm-step8 display-message -p -t smoke:1.1 '#{pane_current_command}'
```

期待値は概ね次のとおり。

```text
tmux-256color
zshへのパス
C-f
on
zsh
```

確認後、隔離したtest serverだけを終了する。

```zsh
TMUX= result/home-path/bin/tmux -L hm-step8 kill-server
```

`-L hm-step8`を付け忘れない。通常利用中のserverに対して`kill-server`を実行しない。

## 12. live設定を回復可能な形で退避する

既存の`~/.config/tmux`はchezmoiが配置した通常directoryなので、そのままではHome Managerと衝突する。末尾の日付は作業日に置き換える。

```zsh
mv ~/.config/tmux ~/.config/tmux.chezmoi-backup-YYYYMMDD
```

確認する。

```zsh
test -d ~/.config/tmux.chezmoi-backup-YYYYMMDD
test ! -e ~/.config/tmux
```

backupはStep 8の確認が終わってもすぐには削除しない。

## 13. Home Managerをswitchする

```zsh
home-manager switch --flake '.#hwata@nixos'
```

配置結果を確認する。

```zsh
ls -ld ~/.config/tmux
ls -l ~/.config/tmux/tmux.conf
readlink -f ~/.config/tmux/tmux.conf
type -a tmux
tmux -V
```

`tmux.conf`がNix store上の生成ファイルを指し、Home Managerのtmuxが優先されていればよい。

## 14. tmux serverを安全に起動し直す

Home Managerのswitchは、すでに動いているtmux serverやpaneを自動終了しない。旧serverは次の値をmemory上に保持している可能性がある。

```text
default-shell /bin/bash
以前のkey binding
以前のTERM設定
```

すべてのsessionで作業を保存する。長時間processが必要なら、serverの再起動だけを都合のよい時間まで延期する。

安全に終了できる場合は、各sessionを通常の操作で閉じる。未保存の作業も終了するため、通常serverに対して安易に`tmux kill-server`を実行しない。

tmux外の新しいzshから確認する。

```zsh
tmux list-sessions
```

`no server running`になったら、新しいserverを起動する。

```zsh
tmux new-session -s main
```

tmux内で確認する。

```zsh
echo "$SHELL"
echo "$TERM"
tmux show-options -gv default-shell
tmux show-options -gv default-terminal
```

`$TERM`と`default-terminal`が`tmux-256color`で、shellがzshならよい。

## 15. tmuxの操作をsmoke testする

最低限、次を確認する。

- `Ctrl-f c`で現在のdirectoryを引き継いだwindowを作れる
- `Ctrl-f |`で横splitできる
- `Ctrl-f -`で縦splitできる
- `Ctrl-f h/j/k/l`でpane間を移動できる
- `Ctrl-f H/J/K/L`でpaneをresizeできる
- mouseでpane選択とscrollができる
- copy modeで`v`、`V`、`C-v`、`y`を利用できる
- status lineが上部へ表示される
- true color表示が崩れない

tmux内でNeovimも起動する。

```zsh
nvim
```

次を確認する。

- insert modeからEscへ遅延なく戻れる
- LSP補完が動く
- Treesitter highlightが崩れない
- yankとpasteがtmux外と同様に動く

OSC 52対応terminalから接続している場合は、tmux copy modeでyankした内容をclient側へpasteできることも確認する。

## 16. chezmoiの管理対象から外れたことを確認する

このStepでは、repository内のchezmoi sourceだった`home/dot_config/tmux/tmux.conf.tmpl`を`dot_config/tmux/tmux.conf`へ移動している。ただし、chezmoiが現在参照しているsource directoryがこのrepositoryとは別にある場合、そちらには古いtemplateが残る。

実際のsource directoryを確認する。

```zsh
chezmoi source-path
```

続けて、tmuxがまだ管理対象か確認する。


```zsh
chezmoi managed ~/.config/tmux
```

何も表示されなければ追加作業は不要である。tmux設定が表示され、chezmoiをすぐにはアンインストールしない場合は、再度`chezmoi apply`したときにHome Managerのsymlinkを上書きしないよう、明示的に管理対象から外す。

まずdry-runする。

```zsh
chezmoi forget --dry-run --verbose ~/.config/tmux/tmux.conf
```

対象がtmux設定だけであることを確認してから実行する。

```zsh
chezmoi forget ~/.config/tmux/tmux.conf
chezmoi managed ~/.config/tmux
```

最後のcommandで何も表示されなければよい。

chezmoiをこの場でアンインストールし、それまで`chezmoi apply`を実行しない場合は`forget`を省略してもよい。その場合は、chezmoiを残したまま移行完了とは扱わない。

`.chezmoiignore`の追加は不要である。これはsourceを残したまま一時的に適用対象から除外する仕組みであり、所有権をHome Managerへ完全に移す今回の用途では、`forget`またはchezmoi自体のアンインストールの方が状態を明確にできる。

## 17. 変更を確認してcommitする

```zsh
git status
git diff --stat
git diff --cached --stat
git diff
git diff --cached
```

特に次を確認する。

- `hosts/common.nix`が共通moduleをimportしている
- `hosts/nixos.nix`にはhost固有値だけがある
- `home/dot_config/tmux/tmux.conf.tmpl`が移動元として削除されている
- `dot_config/tmux/tmux.conf`にchezmoi template構文が残っていない
- `modules/tmux.nix`が追加されている
- `modules/common.nix`からtmux packageが外れている
- `default-shell /bin/bash`が残っていない

問題なければcommitする。

```zsh
git add \
  docs/home-manager-step8-tmux.md \
  hosts/common.nix \
  hosts/nixos.nix \
  modules/common.nix \
  modules/tmux.nix \
  dot_config/tmux/tmux.conf

git commit -m "Manage tmux with Home Manager"
```

## 問題があった場合の戻し方

設定の構文に問題がある場合は、まず通常serverではなくStep 11の隔離socketで修正を確認する。

Home Manager版tmuxを外す場合は、`hosts/common.nix`から`../modules/tmux.nix`のimportを外してbuildとswitchを行う。Home Managerのtmux設定がなくなったことを確認してからbackupを戻す。

```zsh
mv ~/.config/tmux.chezmoi-backup-YYYYMMDD ~/.config/tmux
```

既存の`~/.config/tmux`が残っている状態でbackupを上書きしない。

以前のHome Manager generationへ戻すこともできる。

```zsh
home-manager generations
```

ただしtmux serverは設定をmemoryへ保持するため、generationを戻した後もserverの再起動が必要になる。

## このStepではまだ行わないこと

- Ubuntu hostの追加
- OS固有のtmux設定の分割
- tmux pluginやTPMの導入
- sessionの自動保存・復元
- AI作業用session構成
- `secureSocket = true`への移行
- backup directoryの削除
- NixOS system packages側のtmux削除

まず既存操作を壊さず、tmux本体と設定の管理元をHome Managerへ統一する。

## 完了条件

- `hosts/common.nix`に共通moduleの選択が分離されている
- `hosts/nixos.nix`にはusername、home directory、state versionだけがある
- tmux本体が`programs.tmux`から導入されている
- `dot_config/tmux/tmux.conf`が通常のtmux設定ファイルになっている
- `~/.config/tmux/tmux.conf`がHome Manager管理になっている
- 新しいtmux serverのdefault shellがzshになっている
- tmux内の`TERM`が`tmux-256color`になっている
- prefix、split、pane移動、resize、copy mode、mouseが従来どおり動く
- tmux内のNeovimで色、Esc、LSP、clipboardが動く
- 現在の端末でchezmoiがtmux設定を管理していない
- 旧live設定が回復用backupとして残っている

Step 8完了後は、Gitの一般設定とidentityの分離をHome Managerへ移す。仕事用identityやcredentialをNix storeへ入れず、公開可能な一般設定と秘密・所属依存設定を分けて進める。
