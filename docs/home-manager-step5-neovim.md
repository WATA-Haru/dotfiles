# Home Manager Step 5: Neovim設定をLuaのまま移す

## この手順のゴール

現在chezmoiが管理している`~/.config/nvim`を、Luaの構成を維持したままHome Managerへ移す。

このStepで行うこと：

- live設定とリポジトリの差分を救出する
- `home/dot_config/nvim`を`dot_config/nvim`へ移す
- Neovim本体を`programs.neovim`で管理する
- Home Managerから`~/.config/nvim`を配置する
- 現在の端末でchezmoiのNeovim管理を停止する

このStepではLSPの実行ファイルやmise依存を変更しない。まずNeovim本体とLua設定の所有権だけを安全に移す。

## 現在の状態

現在の設定には三つの管理場所がある。

```text
home/dot_config/nvim   chezmoi用のリポジトリソース
~/.config/nvim         chezmoiが配置したlive設定
~/.local/share/nvim    plugin、parser、sessionなどの可変データ
```

Home Managerへ移すのは`~/.config/nvim`に対応する設定ファイルだけである。`~/.local/share/nvim`はNeovim自身が更新するデータなので、このStepではHome Manager管理にしない。

## 1. Neovimを終了する

設定ディレクトリを切り替える前に、起動中のNeovimを終了する。tmux内の別windowやSSH sessionも確認する。

```zsh
pgrep -a nvim
```

何も表示されない状態にしてから進める。

## 2. live設定との差分を確認する

リポジトリのchezmoiソースと、現在使われている設定を比較する。

```zsh
diff -qr home/dot_config/nvim ~/.config/nvim
```

現時点では、次の差分が確認されている。

```text
lua/plugins/treesitter.lua
```

詳細を確認する。

```zsh
diff -u \
  home/dot_config/nvim/lua/plugins/treesitter.lua \
  ~/.config/nvim/lua/plugins/treesitter.lua
```

live側ではTreesitter parserへ`html`と`css`が追加されている。

```lua
require('nvim-treesitter').install({
  'lua', 'vim', 'vue', 'typescript', 'tsx', 'html', 'css'
})
```

この変更が意図したものなら、移動前に`home/dot_config/nvim/lua/plugins/treesitter.lua`へ反映する。意図しない変更なら取り込まない。

差分を未確認のままディレクトリを置き換えない。

## 3. Neovim設定を`dot_config`へ移す

差分を整理したら、Gitに履歴を追跡させたままディレクトリを移動する。

```zsh
git mv home/dot_config/nvim dot_config/nvim
```

確認する。

```zsh
git status --short
find dot_config/nvim -maxdepth 2 -type f | sort
```

この時点では`~/.config/nvim`は変更されず、現在のNeovimも従来どおり起動できる。

## 4. Neovim用Home Manager moduleを作る

`modules/neovim.nix`を作る。

```nix
{ ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  xdg.configFile."nvim".source = ../dot_config/nvim;
}
```

役割は次のとおり。

| option | 役割 |
| --- | --- |
| `programs.neovim.enable` | Neovim本体を導入する |
| `defaultEditor` | `EDITOR`と`VISUAL`をNeovimへ設定する |
| `viAlias` | `vi`でNeovimを起動する |
| `vimAlias` | `vim`でNeovimを起動する |
| `xdg.configFile."nvim"` | Lua設定ディレクトリを`~/.config/nvim`へ配置する |

設定の実体はLuaのままであり、Nix文字列へ翻訳しない。

`recursive = true`は指定しない。今回は`~/.config/nvim`全体を一つのsymlinkとして管理し、設定ディレクトリの所有者を明確にする。

## 5. `common.nix`の重複を解消する

`programs.neovim.enable = true`がNeovim本体を導入するため、`modules/common.nix`の`home.packages`から`neovim`を外す。

また、`defaultEditor = true`が`EDITOR`と`VISUAL`を設定するため、既存の`home.sessionVariables`も削除できる。

変更後は次のようになる。

```nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ghq
    ripgrep
    tmux
  ];
}
```

同じ設定を複数箇所に残さず、Neovimに関する宣言は`modules/neovim.nix`へ集約する。

## 6. ホスト設定からmoduleを読み込む

`hosts/nixos.nix`の`imports`へ追加する。

```nix
imports = [
  ../modules/common.nix
  ../modules/neovim.nix
  ../modules/zsh.nix
];
```

importの並び順に依存させない。Home Manager moduleは各moduleの宣言を合成する。

## 7. 新しいファイルをGitへ登録する

Flakeが移動先と新しいmoduleを認識できるようにする。

```zsh
git add \
  dot_config/nvim \
  home/dot_config/nvim \
  hosts/nixos.nix \
  modules/common.nix \
  modules/neovim.nix
```

`home/dot_config/nvim`は移動元の削除としてGitへ登録される。`git status`上では、多くのファイルがrenameとして表示される可能性がある。

## 8. switchせずにbuildする

```zsh
nix build '.#homeConfigurations."hwata@nixos".activationPackage'
```

成功したら生成結果を確認する。

```zsh
ls -l result/home-files/.config/nvim
readlink -f result/home-files/.config/nvim
```

さらに、生成物からLua設定を読めることを確認する。

```zsh
test -f result/home-files/.config/nvim/init.lua
rg -n "require\('plugins'\)" \
  result/home-files/.config/nvim/init.lua
```

この時点では、既存`~/.config/nvim`はまだchezmoiが配置した通常ディレクトリである。

## 9. 現在の設定を回復可能な形で退避する

Home Managerは既存の通常ディレクトリを勝手に上書きしないため、そのままswitchすると衝突する。現在の設定を削除せず、名前を変えて退避する。

```zsh
mv ~/.config/nvim ~/.config/nvim.chezmoi-backup-20261004
```

退避を確認する。

```zsh
test -d ~/.config/nvim.chezmoi-backup-20261004
test ! -e ~/.config/nvim
```

このbackupはStep 5の確認が完了しても、すぐには削除しない。

## 10. Home Managerをswitchする

```zsh
home-manager switch --flake '.#hwata@nixos'
```

配置結果を確認する。

```zsh
ls -ld ~/.config/nvim
readlink -f ~/.config/nvim
test -f ~/.config/nvim/init.lua
```

`~/.config/nvim`が`/nix/store/`以下を指すsymlinkになっていれば、Home Managerへの所有権移行に成功している。

今後は`~/.config/nvim`を直接編集しない。編集するのはリポジトリ側である。

```text
dot_config/nvim
      ↓ nix build / home-manager switch
~/.config/nvim -> /nix/store/...
```

## 11. Neovimをsmoke testする

まずheadlessで起動する。

```zsh
nvim --headless '+qa'
```

エラーがなければ通常起動する。

```zsh
nvim
```

最低限、次を確認する。

- `init.lua`が読み込まれる
- mini.nvimと既存pluginが読み込まれる
- `:checkhealth`を実行できる
- 既存keymapが動く
- Treesitterが起動する
- ファイルの編集と保存ができる
- tmux内でも表示とキー操作に問題がない

設定ディレクトリは読み取り専用のNix storeを指すが、pluginやparserなどの可変データは`~/.local/share/nvim`へ保存されるため、通常利用では問題ない。

## 12. LSPが未起動でもこのStepでは正常

現在のLSP設定には、miseのインストール先を直接参照するコードが残っている。

```text
~/.local/share/mise/installs/...
```

対象は主に次のファイルである。

- `lua/lsp/lua_ls.lua`
- `lua/lsp/pyright.lua`
- `lua/lsp/vtsls.lua`
- `lua/lsp/emmet_ls.lua`
- `lua/lsp/marksman.lua`
- `lua/lsp/gh_actions_ls.lua`

各設定には実行ファイルの存在確認があるため、miseがないNixOSでは対象LSPを読み飛ばす。Neovim本体がエラーなく起動すれば、Step 5の範囲では成功とする。

この段階でLSPパスを場当たり的に書き換えない。次のStepでパッケージ名、実行ファイル名、プロジェクト固有性を棚卸ししてNixへ移す。

## 13. 現在の端末でchezmoi管理を停止する

Home Manager版Neovimが正常に動くことを確認した後、chezmoiが将来`~/.config/nvim`を上書きしないよう、現在のchezmoi source stateから外す。

まずdry-runする。

```zsh
chezmoi forget --dry-run --verbose ~/.config/nvim
```

対象がNeovim設定だけであることを確認してから実行する。

```zsh
chezmoi forget ~/.config/nvim
```

管理対象から外れたことを確認する。

```zsh
chezmoi managed ~/.config/nvim
```

何も表示されなければよい。

この操作は現在のchezmoi source stateから対象を外すもので、Home Managerが配置した`~/.config/nvim`を削除する操作ではない。リポジトリ側ではすでに`git mv`で`dot_config/nvim`へ設定を移している。

## 14. 変更を確認してcommitする

```zsh
git status
git diff --stat
git diff --cached --stat
```

特に次を確認する。

- `dot_config/nvim`に全Luaファイルがある
- `home/dot_config/nvim`が移動元として削除されている
- live側にだけ存在した必要な変更を失っていない
- `modules/neovim.nix`が追加されている
- `hosts/nixos.nix`がNeovim moduleをimportしている
- `modules/common.nix`から重複したNeovim設定が消えている

問題なければcommitする。

```zsh
git add \
  dot_config/nvim \
  home/dot_config/nvim \
  hosts/nixos.nix \
  modules/common.nix \
  modules/neovim.nix

git commit -m "Manage Neovim configuration with Home Manager"
```

## 問題があった場合の戻し方

Home Manager版で起動できない場合は、まずエラーを記録する。以前の設定はbackupに残っている。

Home Manager構成から`modules/neovim.nix`のimportを一時的に外してswitchした後、backupを元へ戻せる。

```zsh
mv ~/.config/nvim.chezmoi-backup-20261004 ~/.config/nvim
```

ただし、`~/.config/nvim`にHome Managerのsymlinkが残っている状態では`mv`できない。先にNeovim moduleを外して`home-manager switch`し、symlinkがなくなったことを確認してから戻す。

## このStepではまだ行わないこと

- Neovim pluginをNix packageへ移す
- mini.depsを廃止する
- Treesitter parserをNix管理へ移す
- LSP、formatter、linterをNixへ移す
- miseを削除する
- `~/.local/share/nvim`をHome Manager管理にする
- backupディレクトリを削除する

一度にplugin管理方式やLSP供給方法まで変更すると、起動エラーの原因が分かりにくくなる。Step 5では配置と所有権だけを変更する。

## 完了条件

- Neovim設定が`dot_config/nvim`へ移っている
- live側だけにあった必要な変更を取り込んでいる
- Neovim本体が`programs.neovim`で管理されている
- `~/.config/nvim`がHome Manager管理のsymlinkになっている
- `nvim --headless '+qa'`が成功する
- 通常起動、編集、保存、既存plugin、Treesitterが動く
- 現在の端末でchezmoiが`~/.config/nvim`を管理していない
- 旧設定が回復用backupとして残っている
- LSPが未導入でもNeovim自体はエラーなく起動する

Step 5完了後は、[`home-manager-step6-neovim-lsp.md`](./home-manager-step6-neovim-lsp.md)へ進み、miseの絶対パスを廃止してLSPをNixの`PATH`から起動する構成へ移す。
