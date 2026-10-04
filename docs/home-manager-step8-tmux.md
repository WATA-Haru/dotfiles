# Home Manager Step 8: tmux設定をtemplateから通常ファイルへ移す

## この手順のゴール

chezmoiが生成している`~/.config/tmux/tmux.conf`をHome Manager管理へ移し、tmux本体と設定の所有権を一つにする。

このStepで行うこと：

- tmux本体を`programs.tmux`で管理する
- 共通設定を`dot_config/tmux/tmux.conf`へ移す
- prefix、vi mode、mouseなど標準optionで表せる設定はNix側へ置く
- `default-shell /bin/bash`を廃止し、login shellのzshを使う
- tmux内の`TERM`を`tmux-256color`へ統一する
- macOSの`pbcopy`設定だけをNixのOS分岐で追加する
- 現在の端末でchezmoiのtmux管理を停止する

tmux設定をすべてNix文字列へ翻訳するのではない。Home Managerはpackage、標準option、OS差分を担当し、tmux固有の細かな設定はtmux.confのまま維持する。

## 現在の状態

現在は次の二つがある。

```text
home/dot_config/tmux/tmux.conf.tmpl   chezmoi template
~/.config/tmux/tmux.conf              生成済みのlive設定
```

live設定には次が含まれている。

```tmux
set-option -g default-shell /bin/bash
set -g default-terminal "xterm-256color"
```

ログインシェルはすでにzshへ移行しているため、`default-shell /bin/bash`は現在の方針と矛盾している。また、`default-terminal`はGhosttyなど外側のterminal名ではなく、tmuxが内側のapplicationへ公開するterminal typeを指定するoptionである。

```text
Ghostty / SSH client       外側のterminal
          ↓
        tmux
          ↓ TERM=tmux-256color
   zsh / Neovim / CLI      内側のapplication
```

共通設定では`tmux-256color`を使用する。固定中のNixpkgsのtmux packageにはLinux・macOS用の`tmux-256color` terminfoが含まれている。

## 1. Step 7をcommitして作業を区切る

現在の差分を確認する。

```zsh
git status
git diff
git diff --cached
```

Step 7の変更が残っている場合は、内容を確認して先にcommitする。未確認の変更をまとめてstageしない。

```zsh
git commit -m "Move common CLI tools from mise to Home Manager"
```

すでにcommit済みでworking treeがcleanならそのまま進む。

## 2. tmux sessionとlive設定を確認する

まず現在tmux内にいるか確認する。

```zsh
if [[ -n "$TMUX" ]]; then
  echo "inside tmux: $TMUX"
else
  echo "outside tmux"
fi
```

session一覧も確認する。

```zsh
tmux list-sessions
```

sessionがない場合の`no server running`は問題ない。sessionがある場合は、このStepの最後にserverを再起動するため、未保存のeditorや実行中processがないか覚えておく。

templateとlive設定を比較する。

```zsh
diff -u \
  home/dot_config/tmux/tmux.conf.tmpl \
  ~/.config/tmux/tmux.conf
```

現時点のlive設定はtemplateのLinux向け生成結果であり、live側だけに存在する手修正は確認されていない。自分で変更を追加していた場合は、移動先へ残すか判断する。

## 3. tmux設定を`dot_config`へ移す

移動先を作り、Gitに履歴を追跡させたまま移動する。

```zsh
mkdir -p dot_config/tmux
git mv \
  home/dot_config/tmux/tmux.conf.tmpl \
  dot_config/tmux/tmux.conf
```

この時点では`~/.config/tmux/tmux.conf`は変化せず、既存tmux serverにも影響しない。

## 4. 通常のtmux.confへ整理する

移動した`dot_config/tmux/tmux.conf`を次の内容へ置き換える。

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

# Advertise RGB support for the terminals used on the outside of tmux.
set-option -as terminal-features ",xterm-256color:RGB"
set-option -as terminal-features ",xterm-ghostty:RGB"

# Allow tmux copy operations and `tmux load-buffer -w` to use OSC 52.
set-option -g set-clipboard on
```

元のtemplateから次の設定を削除した理由は、`modules/tmux.nix`の標準optionへ移すためである。

| 元のtmux.conf | 移動先 |
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
| macOSの`pbcopy` bind | Nix側のDarwin条件分岐 |

同じoptionをtmux.confとNixの両方へ残さず、最終値の管理場所を一つにする。

## 5. tmux用Home Manager moduleを作る

`modules/tmux.nix`を作る。

```nix
{ lib, pkgs, ... }:

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

    # 現在の/tmp/tmux-UID socketを維持し、既存sessionを突然見失わない。
    secureSocket = false;

    extraConfig =
      builtins.readFile ../dot_config/tmux/tmux.conf
      + lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
        # Send copy-mode selections to the macOS clipboard.
        bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
        bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "pbcopy"
      '';
  };
}
```

### `shell`を指定しない理由

`programs.tmux.shell`はあえて設定しない。tmuxを新しく起動したとき、tmuxはユーザーのlogin shellを既定値として使う。NixOSではStep 3でユーザーのlogin shellをzshへ変更済みである。

```zsh
getent passwd hwata
```

末尾がzshになっていることを確認する。これによりLinuxとmacOSで異なるzshの絶対パスを共通moduleへ埋め込まずに済む。

既存tmux serverには以前読み込んだ`/bin/bash`がmemory上に残る。そのためswitch後に設定ファイルをsourceするだけではなく、作業を保存してserver自体を一度終了する。手順は後述する。

### `secureSocket = false`について

固定中のHome ManagerはLinuxで既定値を`true`とし、tmux socketを`$XDG_RUNTIME_DIR`へ移す。現在のserverは`/tmp/tmux-1000`を使用しているため、初回移行と同時にsocketを変えると古いsessionが消えたように見える。

このStepでは上流tmux標準の`/tmp/tmux-UID`を維持する。socket移行には機能上の必然性がないため、必要なら全ホスト移行後に独立した変更として検討する。

## 6. `common.nix`からtmuxを外す

`programs.tmux.enable = true`がtmux本体を導入するため、`modules/common.nix`の`home.packages`から`tmux`を削除する。

変更後は次のようになる。

```nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ghq
    ripgrep
  ];
}
```

tmuxに関する宣言は`modules/tmux.nix`へ集約する。

## 7. NixOSホストからtmux moduleを読み込む

`hosts/nixos.nix`の`imports`へ追加する。

```nix
imports = [
  ../modules/cli.nix
  ../modules/common.nix
  ../modules/neovim.nix
  ../modules/tmux.nix
  ../modules/zsh.nix
];
```

同じ`tmux.nix`は将来UbuntuとmacOSからもimportできる。macOSの場合だけ、評価時に`pbcopy`用bindが追加される。

## 8. 新しいファイルをGitへ登録する

Flakeが新しいmoduleと移動先を認識できるようにする。

```zsh
git add \
  dot_config/tmux/tmux.conf \
  hosts/nixos.nix \
  modules/common.nix \
  modules/tmux.nix
```

確認する。

```zsh
git status --short
git diff --cached --stat
```

移動元は削除、移動先は追加またはrenameとして表示される。

## 9. switchせずにbuildする

```zsh
nix build '.#homeConfigurations."hwata@nixos".activationPackage'
```

生成されたtmux.confを確認する。

```zsh
readlink -f result/home-files/.config/tmux/tmux.conf
sed -n '1,260p' result/home-files/.config/tmux/tmux.conf
```

Home Managerが生成した前半と、`dot_config/tmux/tmux.conf`から取り込んだ後半が一つのファイルになっている。

重要な設定を検索する。

```zsh
rg -n \
  'default-terminal|base-index|mode-keys|mouse|prefix|escape-time|focus-events|set-clipboard' \
  result/home-files/.config/tmux/tmux.conf
```

次を確認する。

- `default-terminal`が`tmux-256color`
- windowとpaneの`base-index`が1
- key modeがvi
- mouseがon
- prefixが`C-f`
- `escape-time`が0
- `focus-events`がon
- `set-clipboard`がon
- `default-shell /bin/bash`が存在しない

NixOS向け生成物へ`pbcopy`が入っていないことも確認する。

```zsh
if rg -n 'pbcopy' result/home-files/.config/tmux/tmux.conf; then
  echo 'unexpected: macOS clipboard setting exists on Linux'
  false
else
  echo 'ok: no macOS-only clipboard setting'
fi
```

## 10. 隔離したtmux serverで構文を確認する

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
/run/current-system/sw/bin/zsh
C-f
on
zsh
```

`default-shell`の実際のパスはホストによって異なるが、`/bin/bash`ではなくzshであればよい。

確認後、隔離したtest serverだけを終了する。

```zsh
TMUX= result/home-path/bin/tmux -L hm-step8 kill-server
```

`-L hm-step8`を付け忘れない。通常利用中のserverに対して`kill-server`を実行しない。

## 11. live設定を回復可能な形で退避する

既存の`~/.config/tmux`はchezmoiが配置した通常directoryなので、そのままではHome Managerと衝突する。tmux serverは設定をmemoryへ読み込み済みなので、directoryを退避しても現在のpaneは直ちには終了しない。

```zsh
mv ~/.config/tmux ~/.config/tmux.chezmoi-backup-20261004
```

確認する。

```zsh
test -d ~/.config/tmux.chezmoi-backup-20261004
test ! -e ~/.config/tmux
```

backupはStep 8の確認が終わってもすぐには削除しない。

## 12. Home Managerをswitchする

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

`tmux.conf`がNix store上の生成ファイルを指し、`/home/hwata/.nix-profile/bin/tmux`が優先されていればよい。

## 13. 既存serverを安全に終了して起動し直す

Home Managerのswitchは、すでに動いているtmux serverやpaneを自動終了しない。旧serverは次をmemory上に保持している可能性がある。

```text
default-shell /bin/bash
以前のkey binding
以前のTERM設定
```

すべてのtmux sessionで作業を保存する。長時間processが必要なら、この時点ではserverを終了せず、都合のよい時間までStep 13以降を延期する。

安全に終了できる場合は、各sessionを通常の操作で閉じ、最後のsessionがなくなったことを確認する。強制的な`tmux kill-server`は未保存作業も終了させるため、この手順では通常serverに対して実行しない。

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

期待値は次のとおり。

```text
SHELL: zshへのパス
TERM: tmux-256color
default-shell: zshへのパス
default-terminal: tmux-256color
```

## 14. tmuxの操作をsmoke testする

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
- `dev`関数をtmux内で使うとsession名が変わる

Neovimもtmux内で起動する。

```zsh
nvim
```

次を確認する。

- insert modeからEscへ遅延なく戻れる
- `:checkhealth vim.lsp`を実行できる
- true colorとTreesitter highlightが崩れない
- yank・pasteがtmux外と同様に動く

LinuxからGhosttyなどOSC 52対応terminalへ接続している場合、tmux copy-modeでyankした内容をclient側へpasteできることも確認する。

## 15. 現在の端末でchezmoi管理を停止する

Home Manager版tmuxが正常に動くことを確認した後、chezmoiの管理対象から外す。

まずdry-runする。

```zsh
chezmoi forget --dry-run --verbose ~/.config/tmux/tmux.conf
```

対象がtmux設定だけであることを確認してから実行する。

```zsh
chezmoi forget ~/.config/tmux/tmux.conf
```

管理対象から外れたことを確認する。

```zsh
chezmoi managed ~/.config/tmux
```

何も表示されなければよい。chezmoi側ですでに移動元が存在しないため`forget`が「管理対象ではない」と報告する場合も、`chezmoi managed`が空なら目的を満たしている。

## 16. 変更を確認してcommitする

```zsh
git status
git diff --stat
git diff --cached --stat
git diff
git diff --cached
```

特に次を確認する。

- `home/dot_config/tmux/tmux.conf.tmpl`が移動元として削除されている
- `dot_config/tmux/tmux.conf`にchezmoi template構文が残っていない
- `modules/tmux.nix`が追加されている
- `modules/common.nix`からtmux packageが外れている
- `hosts/nixos.nix`がtmux moduleをimportしている
- `default-shell /bin/bash`が残っていない
- macOS固有の`pbcopy`がNixのDarwin分岐だけにある

問題なければcommitする。

```zsh
git add \
  dot_config/tmux/tmux.conf \
  hosts/nixos.nix \
  modules/common.nix \
  modules/tmux.nix

git commit -m "Manage tmux with Home Manager"
```

## 問題があった場合の戻し方

設定の構文に問題がある場合は、まず通常serverではなくStep 10の隔離socketで修正を確認する。

Home Manager版全体を戻す場合は、`hosts/nixos.nix`からtmux moduleのimportを外し、buildとswitchを行う。Home Managerの`tmux.conf`がなくなったことを確認してからbackupを戻す。

```zsh
mv ~/.config/tmux.chezmoi-backup-20261004 ~/.config/tmux
```

既存の`~/.config/tmux`が残っている状態でbackupを上書きしない。

以前のHome Manager generationへ戻す方法もある。

```zsh
home-manager generations
```

ただしtmux serverは設定をmemoryへ保持するため、generationを戻しただけではすでに動いているserverの設定は変わらない。必要な作業を保存し、serverを終了してから再起動する。

## このStepではまだ行わないこと

- tmux pluginの追加
- TPMの導入
- session自動保存・復元
- AI作業用session/window/pane構成
- `secureSocket = true`へのsocket移行
- Ghostty本体やterminfoのsystem設定
- backup directoryの削除
- NixOS system packages側のtmux削除

まず既存操作を壊さず、tmux本体・共通設定・OS差分の管理元をHome Managerへ統一する。

## 完了条件

- tmux本体が`programs.tmux`から導入されている
- `dot_config/tmux/tmux.conf`が通常のtmux設定ファイルになっている
- `~/.config/tmux/tmux.conf`がHome Manager管理になっている
- 新しいtmux serverのdefault shellがzshになっている
- tmux内の`TERM`が`tmux-256color`になっている
- prefix、split、pane移動、resize、copy mode、mouseが従来どおり動く
- tmux内のNeovimで色、Esc、LSP、clipboardが動く
- Linuxの生成設定へmacOS専用`pbcopy`が入っていない
- 現在の端末でchezmoiがtmux設定を管理していない
- 旧live設定が回復用backupとして残っている

Step 8完了後は、Gitの一般設定とidentityの分離をHome Managerへ移す。ただし仕事用identityやcredentialをNix storeへ入れず、公開可能な一般設定と秘密・所属依存設定を分けて進める。
