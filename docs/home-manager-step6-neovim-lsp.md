# Home Manager Step 6: NeovimのLSPをmiseの絶対パスからNixへ移す

## この手順のゴール

NeovimのLua設定に埋め込まれている次のようなmise固有のパスをなくす。

```text
~/.local/share/mise/installs/...
```

Home ManagerがLSPをNeovim専用の`PATH`へ追加し、Lua側は`lua-language-server`のような実行ファイル名だけで起動する構成へ移す。

このStepでNixへ移すもの：

| 用途 | Nixpkgsのpackage | Neovimから呼ぶcommand |
| --- | --- | --- |
| Lua | `lua-language-server` | `lua-language-server` |
| Markdown | `marksman` | `marksman server` |
| Python | `pyright` | `pyright-langserver --stdio` |
| HTML/CSSなどのEmmet | `emmet-language-server` | `emmet-language-server --stdio` |
| TypeScript/JavaScript | `vtsls` | `vtsls --stdio` |
| Vue | `vue-language-server` | `vue-language-server --stdio` |

`flake.lock`で固定されているNixpkgsを確認したところ、GitHub Actions用の`gh-actions-language-server`はpackageとして収録されていない。この一つだけはNix package化せず、`PATH`上に存在すれば使う任意ツールとして残す。

## なぜ`home.packages`ではなく`extraPackages`なのか

今回のLSPはNeovimからだけ使えればよいので、`programs.neovim.extraPackages`へ置く。

```text
Home Manager
    └── wrapped nvimのPATH
            ├── lua-language-server
            ├── pyright-langserver
            └── ...
```

この方法では通常のshellの`PATH`をLSPで埋めずに済む。そのため、switch後にshellで`type -a lua-language-server`が見つからなくても異常ではない。Home Managerが生成した`nvim`の中から見つかればよい。

Python、Node.js、TypeScriptなど、プロジェクトが実際に実行する言語処理系やライブラリは引き続きプロジェクト側のdevShellで管理する。LSP本体とプロジェクトのruntimeは別の役割である。

## 1. Step 5の状態を確認する

リポジトリのルートで実行する。

```zsh
test -L ~/.config/nvim
readlink -f ~/.config/nvim
nvim --headless '+qa'
```

miseの絶対パスが残っているファイルも確認する。

```zsh
rg -n '\.local/share/mise|mise/installs' dot_config/nvim/lua/lsp
```

現時点では次の6ファイルが見つかるはずである。

```text
lua/lsp/lua_ls.lua
lua/lsp/pyright.lua
lua/lsp/vtsls.lua
lua/lsp/emmet_ls.lua
lua/lsp/marksman.lua
lua/lsp/gh_actions_ls.lua
```

## 2. `common.nix`の重複を片付ける

現在の`modules/common.nix`には`EDITOR`と`VISUAL`が残っている。Step 5で設定した`programs.neovim.defaultEditor = true`と重複するため、`home.sessionVariables`を削除する。

変更後の`modules/common.nix`は次の形になる。

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

これはLSP移行の必須条件ではないが、どのmoduleが設定の責任を持つかを今のうちに明確にするための整理である。

## 3. Neovim専用のLSP packageを追加する

`modules/neovim.nix`を次のように変更する。

```nix
{ pkgs, ... }:

let
  vueLanguageServerRoot =
    "${pkgs.vue-language-server}/lib/language-tools/packages/language-server";
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [
      # nvim-treesitterがparserをdownload・buildするために必要
      curl
      gnutar
      stdenv.cc
      tree-sitter

      # Language servers
      emmet-language-server
      lua-language-server
      marksman
      pyright
      vtsls
      vue-language-server
    ];

    extraWrapperArgs = [
      "--set"
      "VUE_LANGUAGE_SERVER_PATH"
      vueLanguageServerRoot
    ];
  };

  xdg.configFile."nvim".source = ../dot_config/nvim;
}
```

`extraPackages`は各実行ファイルをwrapped Neovimの`PATH`へ追加する。

現在使用している全面改訂後のnvim-treesitterは、parserのinstall時に`curl`、`tar`、tree-sitter CLI 0.26.1以上、C compilerを要求する。固定中のNixpkgsが提供する`tree-sitter`は0.26.11で要件を満たす。`stdenv.cc`はLinuxではGCC系、macOSではClang系の適切なcompiler wrapperを選ぶため、`gcc`を直接指定するよりホスト間で共有しやすい。

`VUE_LANGUAGE_SERVER_PATH`だけは実行ファイルではなく、vtslsへ渡すVue TypeScript pluginのディレクトリである。LuaにNix storeのパスを直書きせず、Nix側で計算した値をNeovimの環境変数として渡す。

この内部ディレクトリはNixpkgs側のpackage構造に依存する。将来Nixpkgs更新後にVueだけ起動しなくなった場合は、最初にこの値を確認する。

## 4. Lua LSPをcommand名で起動する

`dot_config/nvim/lua/lsp/lua_ls.lua`の冒頭を置き換える。

```lua
local command = 'lua-language-server'

if vim.fn.executable(command) ~= 1 then
  return {}
end

return {
  cmd = { command },
```

`return`以下にある`filetypes`、`on_init`、`settings`はそのまま残す。削除するのは`HOME`からmiseのパスを組み立てる処理だけである。

## 5. Marksmanをcommand名で起動する

`dot_config/nvim/lua/lsp/marksman.lua`を次のようにする。

```lua
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#marksman
local command = 'marksman'

if vim.fn.executable(command) ~= 1 then
  return {}
end

return {
  cmd = { command, 'server' },
  filetypes = { 'markdown', 'markdown.mdx' },
  root_markers = { '.marksman.toml', '.git' },
}
```

既存設定の`root_markers`にあった`markdown.mdx`はファイル名であり、project rootの印ではないため`.git`へ直す。

## 6. Pyrightをcommand名で起動する

`dot_config/nvim/lua/lsp/pyright.lua`からNode.jsファイルの絶対パスと`node`の確認を削除する。

```lua
local command = 'pyright-langserver'

if vim.fn.executable(command) ~= 1 then
  return {}
end

return {
  cmd = { command, '--stdio' },
  filetypes = { 'python' },
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = 'workspace',
        useLibraryCodeForTypes = true,
      },
    },
  },
}
```

Nixpkgsの`pyright` packageがNode.js込みのwrapperを提供するため、Neovimから`node .../langserver.index.js`と起動する必要はない。

この変更はPython interpreterやproject dependencyを導入するものではない。それらは対象projectのdevShell、virtualenv、または残しているmiseから供給する。

## 7. Emmet Language Serverをcommand名で起動する

`dot_config/nvim/lua/lsp/emmet_ls.lua`では既存の`filetypes`と`root_markers`を残し、パスの判定と`cmd`だけを変更する。

```lua
local command = 'emmet-language-server'

if vim.fn.executable(command) ~= 1 then
  return {}
end

return {
  cmd = { command, '--stdio' },
```

これもNix package側にNode.jsのshebangが組み込まれているため、Lua側で`node`を探す必要はない。

## 8. vtslsとVue Language Serverを移す

`dot_config/nvim/lua/lsp/vtsls.lua`を次の内容へ置き換える。

```lua
-- ref: https://github.com/vuejs/language-tools/wiki/Neovim
-- ref: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#vtsls
local vtsls_command = 'vtsls'
local vue_command = 'vue-language-server'
local vue_language_server_path = os.getenv('VUE_LANGUAGE_SERVER_PATH')

local has_vtsls = vim.fn.executable(vtsls_command) == 1
local has_vue = vim.fn.executable(vue_command) == 1
  and type(vue_language_server_path) == 'string'
  and vim.uv.fs_stat(vue_language_server_path) ~= nil

if not has_vtsls then
  return {}
end

local tsserver_filetypes = {
  'typescript',
  'javascript',
  'javascriptreact',
  'typescriptreact',
}

if has_vue then
  table.insert(tsserver_filetypes, 'vue')
end

local vtsls_config = {
  cmd = { vtsls_command, '--stdio' },
  settings = {},
  filetypes = tsserver_filetypes,
}

if has_vue then
  vtsls_config.settings = {
    vtsls = {
      tsserver = {
        globalPlugins = {
          {
            name = '@vue/typescript-plugin',
            location = vue_language_server_path,
            languages = { 'vue' },
            configNamespace = 'typescript',
          },
        },
      },
    },
  }
end

local configs = {
  vtsls = vtsls_config,
}

if has_vue then
  configs.vue_ls = {
    cmd = { vue_command, '--stdio' },
    filetypes = { 'vue' },
  }
end

return configs
```

既存設定の`configs.vue_ls = {}`は、`lua/lsp/init.lua`の空table除外処理によって読み飛ばされる。`cmd`と`filetypes`を明示することで、Vue Language Serverも実際に有効化される。

## 9. GitHub Actions LSPから絶対パスだけを外す

`gh-actions-language-server`は固定中のNixpkgsにないため、このStepではHome Managerのpackage一覧へ追加しない。ただし、Luaをmiseのディレクトリ構造へ依存させる必要もない。

`dot_config/nvim/lua/lsp/gh_actions_ls.lua`の冒頭を次のように変更する。

```lua
-- https://github.com/neovim/nvim-lspconfig/blob/master/lsp/gh_actions_ls.lua
local command = 'gh-actions-language-server'

if vim.fn.executable(command) ~= 1 then
  return {}
end

return {
  cmd = { command, '--stdio' },
```

`filetypes`以降の設定はそのまま残す。

これにより、miseなどがcommandを`PATH`へ提供する端末では引き続き利用でき、未導入の端末では静かに無効になる。後から必要性を確認したうえで、次のいずれかを別Stepとして選ぶ。

- このLSPだけmiseで管理する
- 小さなNix packageを自作する
- YAML Language ServerとGitHub Actions schemaで代替する

Step 6では独自package作成まで広げない。

## 10. miseの絶対パスが消えたことを確認する

```zsh
rg -n '\.local/share/mise|mise/installs' dot_config/nvim/lua/lsp
```

何も表示されなければよい。

LSPのcommandも一覧で確認する。

```zsh
rg -n 'cmd = ' dot_config/nvim/lua/lsp
```

## 11. switchせずにbuildする

新規ファイルはないが、編集内容がGitの管理対象にあることを確認する。

```zsh
git status --short
```

buildする。

```zsh
nix build '.#homeConfigurations."hwata@nixos".activationPackage'
```

通常のshellからではなく、buildしたwrapped Neovimの内部でcommandを検索する。

```zsh
result/home-path/bin/nvim --headless \
  "+lua for _, cmd in ipairs({ 'lua-language-server', 'marksman', 'pyright-langserver', 'emmet-language-server', 'vtsls', 'vue-language-server' }) do print(cmd .. ': ' .. vim.fn.exepath(cmd)) end" \
  '+qa'
```

6個すべてについて`/nix/store/...`のパスが表示されればよい。

nvim-treesitterのbuild toolも同様に確認する。

```zsh
result/home-path/bin/nvim --headless \
  "+lua for _, cmd in ipairs({ 'tree-sitter', 'cc', 'curl', 'tar' }) do print(cmd .. ': ' .. vim.fn.exepath(cmd)) end" \
  '+qa'
```

4個すべてについて実行ファイルのパスが表示されればよい。`tree-sitter`と`cc`が通常のshellで見つからなくても、wrapped Neovim内から見つかれば問題ない。

Vue plugin用の環境変数も確認する。

```zsh
result/home-path/bin/nvim --headless \
  "+lua print(vim.env.VUE_LANGUAGE_SERVER_PATH or 'missing')" \
  '+qa'
```

`/nix/store/...-vue-language-server/lib/language-tools/packages/language-server`が表示されることを確認する。

## 12. Home Managerをswitchする

```zsh
home-manager switch --flake '.#hwata@nixos'
```

新しいgenerationのNeovimを確認する。

```zsh
type -a nvim
nvim --headless '+qa'
nvim --headless \
  "+lua print(vim.fn.exepath('lua-language-server'))" \
  '+qa'
```

最後のcommandがNix store上の実行ファイルを表示すれば、Neovim専用`PATH`が反映されている。

## 13. LSPを一つずつsmoke testする

一度に全部の原因を追わず、まずこのリポジトリのLuaファイルで確認する。

```zsh
nvim dot_config/nvim/init.lua
```

Neovim内で少し待ってから実行する。

```vim
:LspHealth
:lua =vim.lsp.get_clients({ bufnr = 0 })
```

`lua_ls`のclientが表示され、`gd`など既存のLSP keymapが動くことを確認する。

次に、実際に使うprojectで対象ファイルを開いて確認する。

| file | 期待するclient |
| --- | --- |
| `*.md` | `marksman` |
| `*.py` | `pyright` |
| `*.ts` / `*.tsx` | `vtsls` |
| `*.vue` | `vtsls`と`vue_ls` |
| HTML/CSS/JSX/Vue | `emmet_ls` |
| `.github/workflows/*.yml` | commandが別途存在する端末だけ`gh_actions_ls` |

Vueでは特に`<template>`内の補完と、`<script setup lang="ts">`側の型情報を確認する。二つのclientがattachしていても、同じdiagnosticやcompletionが過剰に重複していないかを見る。

## 14. mise側はまだ削除しない

このStepでは、miseのLSP installationやcacheを削除しない。まず数日使い、Neovimが常にNix版を起動していることを確認する。

Neovim内で実行する。

```vim
:lua =vim.fn.exepath('pyright-langserver')
:lua =vim.fn.exepath('vtsls')
```

`/nix/store/`以下を指していればNix版である。安定後にmise側の重複を棚卸しする。削除はStep 6の完了条件ではない。

## 問題があった場合の切り分け

### `nix build`でpackage名がないと言われる

まず`flake.lock`が意図せず更新されていないか確認する。

```zsh
git diff -- flake.lock
```

この文書は2026-10-04時点で、このリポジトリが固定しているNixpkgsを基準にpackage名を確認している。

### shellではLSPが見つからない

`extraPackages`はNeovim wrapper専用であるため正常である。次で確認する。

```zsh
nvim --headless \
  "+lua print(vim.fn.exepath('pyright-langserver'))" \
  '+qa'
```

### commandは見つかるがclientがattachしない

Neovim内で次を順番に確認する。

```vim
:messages
:LspHealth
:lua =vim.lsp.get_clients({ bufnr = 0 })
:lua =vim.inspect(vim.lsp.config.lua_ls)
```

対象filetypeとproject rootも確認する。

```vim
:set filetype?
:pwd
```

### Treesitterで`ENOENT: 'tree-sitter'`と表示される

LSPではなく、parserをbuildするためのtree-sitter CLIが不足している。新しいgenerationのNeovimから必要なcommandが見えるか確認する。

```zsh
nvim --headless \
  "+lua for _, cmd in ipairs({ 'tree-sitter', 'cc', 'curl', 'tar' }) do print(cmd .. ': ' .. vim.fn.exepath(cmd)) end" \
  '+qa'
```

空の項目があれば、`modules/neovim.nix`の`extraPackages`と、build・switchが完了しているかを確認する。すべて見つかったら通常起動したNeovimでparserのdownloadとbuildが完了するまで待つ。`nvim --headless '+qa'`は非同期installの完了前に終了することがあるため、最初のinstall確認には使わない。

### Vueだけ動かない

次を確認する。

```vim
:lua =vim.env.VUE_LANGUAGE_SERVER_PATH
:lua =vim.uv.fs_stat(vim.env.VUE_LANGUAGE_SERVER_PATH)
:lua =vim.fn.exepath('vue-language-server')
```

環境変数がない場合は新しいHome Manager generationの`nvim`を起動しているか確認する。パスはあるがpluginを読めない場合は、Nixpkgs更新によって`vue-language-server`の内部構造が変わっていないか調べる。

## 戻し方

LSPの変更だけでNeovim本体が起動不能になる可能性は低い。問題のあるLSP設定が空tableを返せば、そのLSPだけ無効にできる。

全体を戻す場合は、`modules/neovim.nix`の`extraPackages`と`extraWrapperArgs`、および今回変更したLuaファイルを直前のcommitへ戻してから、再度buildとswitchを行う。未確認の変更が同じファイルにある場合は、ファイル全体を機械的に戻さず差分を選んで戻す。

## このStepではまだ行わないこと

- miseそのものの削除
- miseに残る言語runtimeやproject toolの一括移行
- `gh-actions-language-server`の独自Nix package作成
- formatter、linterの移行
- Neovim pluginやTreesitter parserのNix管理
- devShellやdirenvの設計

LSPの供給元だけを切り替え、plugin管理方式やproject環境を同時に変更しない。

## 完了条件

- 6種のLSP packageが`programs.neovim.extraPackages`から供給されている
- nvim-treesitterが必要とする`tree-sitter`、`cc`、`curl`、`tar`をwrapped Neovimから実行できる
- `dot_config/nvim/lua/lsp`にmiseの絶対パスが残っていない
- Lua側が`PATH`上のcommand名でLSPを起動している
- wrapped Neovim内の`vim.fn.exepath()`がNix storeを指す
- Lua、Markdown、Python、TypeScriptのうち実際に使えるprojectでclientのattachを確認した
- Vue projectで`vtsls`と`vue_ls`のattach、および`<template>`補完を確認した
- `gh_actions_ls`はcommandがない端末でもNeovimの起動を妨げない
- mise側のinstallationは、動作確認が済むまで回復用として残っている

Step 6完了後は、tmux設定のHome Manager移行へ進むのがよい。LSP以外のformatter・linterは、実際の使用状況を棚卸ししてから別Stepに分ける。
