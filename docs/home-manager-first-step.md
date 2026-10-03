# Home Manager 最初の一歩

## この手順のゴール

最初からzshやNeovimを移行しない。まず次の流れを一度経験する。

1. 最小のHome Manager構成を書く
2. ホーム環境を変更せずにbuildする
3. 最小構成をactivateする
4. パッケージを一つ追加してswitchする

対象は現在のNixOSマシンとする。

| 項目 | 値 |
| --- | --- |
| ユーザー | `hwata` |
| ホスト | `nixos` |
| system | `x86_64-linux` |
| 構成名 | `hwata@nixos` |

このdotfilesリポジトリでは、NixOS全体へHome Managerを統合する方式ではなく、まずstandalone Home Managerを使用する。UbuntuとmacOSでも同じHome Manager moduleを再利用しやすく、NixOS本体の変更とdotfilesの変更を分けて学べるためである。

## 1. `flake.nix`を作る

リポジトリ直下に`flake.nix`を作る。

```nix
{
  description = "hwata's Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations."hwata@nixos" =
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = [
            ./hosts/nixos.nix
          ];
        };
    };
}
```

最初に把握する要素は次の三つだけでよい。

- `inputs`: 利用する外部のNixコード
- `outputs`: このflakeが提供する構成
- `homeConfigurations."hwata@nixos"`: build・switch時に指定するHome Manager構成

`inputs.nixpkgs.follows = "nixpkgs"`により、Home Managerとこの構成が同じNixpkgs revisionを利用する。

公式ドキュメントのNixOS統合例では、次のようにsystemを指定する。

```nix
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
}
```

standalone Home Managerでは、systemを指定して作ったpackage setを`pkgs`へ渡す。

```nix
pkgs = nixpkgs.legacyPackages.${system};
```

したがって、systemを省略しているわけではなく、指定場所が異なる。

## 2. 最小のホスト設定を作る

`hosts/nixos.nix`を作る。

```nix
{ ... }:

{
  home.username = "hwata";
  home.homeDirectory = "/home/hwata";

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
```

`home.stateVersion`は、利用中のHome ManagerやNixpkgsのバージョン番号ではない。設定の互換性基準であるため、最初に決めた後はNixpkgsの更新に合わせて安易に変更しない。

## 3. 新しいファイルをGitの管理対象にする

Git管理されたディレクトリをflakeとして評価する場合、未追跡ファイルがflakeの入力に含まれず、参照したファイルが見つからないことがある。build前に追加する。

```bash
git add flake.nix hosts/nixos.nix
```

この時点でcommitする必要はない。

## 4. 構成をbuildする

リポジトリ直下で実行する。

```bash
nix build '.#homeConfigurations."hwata@nixos".activationPackage'
```

初回はNixpkgsとHome Managerを取得するため時間がかかる。成功すると、リポジトリ直下に`result` symlinkと`flake.lock`ができる。

```bash
ls -l result
ls result
```

`flake.lock`は依存先の具体的なrevisionを固定するファイルなので、Gitで管理する。

```bash
git add flake.lock
```

`nix build`だけでは、まだホーム環境は変更されない。

## 5. 最小構成をactivateする

buildが成功したら、初回は生成したactivation packageを直接実行する。

```bash
./result/activate
```

今回の構成は既存の設定ファイルや追加パッケージをまだ管理しないため、既存dotfilesとの衝突範囲が小さい。

Home Managerが利用可能になったことを確認する。

```bash
home-manager generations
```

## 6. パッケージを一つ追加する

`modules/common.nix`を作る。

```nix
{ pkgs, ... }:

{
  home.packages = [
    pkgs.ripgrep
  ];
}
```

`hosts/nixos.nix`から読み込む。

```nix
{ ... }:

{
  imports = [
    ../modules/common.nix
  ];

  home.username = "hwata";
  home.homeDirectory = "/home/hwata";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
```

新しいファイルをGitの管理対象にしてからbuildする。

```bash
git add modules/common.nix hosts/nixos.nix
nix build '.#homeConfigurations."hwata@nixos".activationPackage'
```

buildが成功したらswitchする。

```bash
home-manager switch --flake '.#hwata@nixos'
```

反映結果を確認する。

```bash
command -v rg
rg --version
```

ここまでで、Home Managerの基本的なデータの流れを一周できる。

```text
flake.nix
    ↓ 対象ホストを選ぶ
hosts/nixos.nix
    ↓ 機能moduleをimportする
modules/common.nix
    ↓ パッケージを宣言する
pkgs.ripgrep
    ↓ build / switch
ホーム環境へ反映される
```

## この段階では行わないこと

次の作業は、上記の一周が成功してから一つずつ行う。

- `.bashrc`を置き換える
- ログインシェルをzshへ変更する
- Neovim設定を移動する
- miseを削除する
- chezmoiの管理対象を外す
- UbuntuとmacOSの構成を同時に作る
- 既存ファイルへ`force = true`を指定する

次のマイルストーンは、zshをHome Managerへ追加し、既存bash環境を残したまま対話起動を確認することとする。
