# Nix command cheat sheet

このrepositoryでは、NixOSとHome Managerを同じflakeで管理する。ただしHome ManagerはNixOS moduleへ統合せず、standaloneで反映する。

```text
NixOS        sudo nixos-rebuild ... --flake '.#nixos'
Home Manager home-manager ... --flake '.#hwata@nixos'
```

`nix build switch`というcommandは存在しない。`build`で検証した後、NixOSは`nixos-rebuild test`または`nixos-rebuild switch`、Home Managerは`home-manager switch`で反映する。

## 普段使う手順

### Home Managerだけ変更した場合

```zsh
nix flake check --no-build

nix build --no-link \
  '.#homeConfigurations."hwata@nixos".activationPackage'

home-manager switch --flake '.#hwata@nixos'
```

### NixOSだけ変更した場合

最初に、system closureをactivationせずにbuildする。

```zsh
nix flake check --no-build

nix build --no-link \
  '.#nixosConfigurations.nixos.config.system.build.toplevel'
```

一時的に適用する。`test`で作った構成はboot defaultにならないため、再起動すると最後に`switch`または`boot`した構成へ戻る。

```zsh
sudo nixos-rebuild test --flake '.#nixos'
```

network、SSH、shell、sudoなどを確認する。

```zsh
systemctl status sshd
getent passwd hwata
sudo -v
```

問題がなければ、現在のsystemへ反映し、次回bootのdefaultにする。

```zsh
sudo nixos-rebuild switch --flake '.#nixos'
```

### NixOSとHome Managerの両方を変更した場合

```zsh
nix flake check --no-build

nix build --no-link \
  '.#nixosConfigurations.nixos.config.system.build.toplevel'

nix build --no-link \
  '.#homeConfigurations."hwata@nixos".activationPackage'

sudo nixos-rebuild test --flake '.#nixos'
sudo nixos-rebuild switch --flake '.#nixos'
home-manager switch --flake '.#hwata@nixos'
```

## Commandの意味

### Flake全体を評価する

```zsh
nix flake check --no-build
```

- flake outputsとmodule optionsを評価する
- packageやsystem closure自体はbuildしない
- input URLを変更した場合は`flake.lock`が更新されることがある

### NixOSをbuildするが反映しない

result symlinkを作らない場合はこちらを使う。

```zsh
nix build --no-link \
  '.#nixosConfigurations.nixos.config.system.build.toplevel'
```

result symlinkを作り、生成物を確認したい場合はこちらを使う。

```zsh
nixos-rebuild build --flake '.#nixos'
readlink -f result
```

`nixos-rebuild build`はactivationもboot defaultの変更もしないため、通常は`sudo`不要である。

### NixOSを一時的に反映する

```zsh
sudo nixos-rebuild test --flake '.#nixos'
```

- running systemへ反映する
- boot defaultにはしない
- rebootすれば以前のboot defaultへ戻る

### 次回bootだけ変更する

```zsh
sudo nixos-rebuild boot --flake '.#nixos'
```

- running systemは変更しない
- 次回bootのdefaultを新しい構成にする

### NixOSを永続的に反映する

```zsh
sudo nixos-rebuild switch --flake '.#nixos'
```

- running systemへ反映する
- 次回bootのdefaultにもする
- 古いgenerationはrollback用に残る

### Home Managerをbuildするが反映しない

```zsh
nix build --no-link \
  '.#homeConfigurations."hwata@nixos".activationPackage'
```

### Home Managerの変更予定を確認する

```zsh
home-manager -n switch --flake '.#hwata@nixos'
```

### Home Managerを反映する

```zsh
home-manager switch --flake '.#hwata@nixos'
```

## Flake inputを更新する

通常の`switch`ではinputを更新しない。NixpkgsとHome Managerを更新したいときだけ、明示的に更新する。

```zsh
nix flake update nixpkgs home-manager
```

変更内容を確認する。

```zsh
git diff -- flake.lock
nix flake metadata
```

更新後はすぐにswitchせず、最初に評価とbuildを行う。

```zsh
nix flake check --no-build

nix build --no-link \
  '.#nixosConfigurations.nixos.config.system.build.toplevel'

nix build --no-link \
  '.#homeConfigurations."hwata@nixos".activationPackage'
```

問題がなければlock fileをcommit対象へ加える。

```zsh
git add flake.lock
```

## Generationを確認する

### NixOS

```zsh
nixos-version
readlink -f /run/current-system
sudo nixos-rebuild list-generations
```

### Home Manager

```zsh
home-manager generations
```

## Rollback

### NixOSを一つ前へ戻す

flake-only構成では、`nixos-rebuild switch --rollback`がlegacyの`NIX_PATH`から`nixos-config`を探して失敗する場合がある。system profileを一つ前へ戻してから、そのgenerationをactivateする。

最初に、rollback先を確認する。

```zsh
nix profile history \
  --profile /nix/var/nix/profiles/system
```

profile変更のdry runを行う。

```zsh
sudo nix profile rollback --dry-run \
  --profile /nix/var/nix/profiles/system
```

問題がなければ、system profileを一つ前へ戻してactivateする。

```zsh
sudo nix profile rollback \
  --profile /nix/var/nix/profiles/system

sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

確認する。

```zsh
readlink -f /run/current-system
readlink -f /nix/var/nix/profiles/system
nixos-version
```

確認後、このrepositoryのflakeを再適用する。

```zsh
sudo nixos-rebuild switch --flake '.#nixos'
```

bootできない場合は、boot menuから以前のNixOS generationを選択する。

### Home Managerを一つ前へ戻す

```zsh
home-manager switch --rollback
```

## Gitへ追加する前の確認

Git-based flakeはuntracked fileを入力へ含めない。新しいNix fileを作った場合は、build前にstagingする。

```zsh
git status --short
git add path/to/new-file.nix
nix flake check --no-build
```

commit前に確認する。

```zsh
git diff --staged --check
git diff --staged
```

## 覚えるcommandを最小限にする

普段は次の5つを覚えておけばよい。

```zsh
# 評価だけ
nix flake check --no-build

# Home Managerをbuild
nix build --no-link \
  '.#homeConfigurations."hwata@nixos".activationPackage'

# Home Managerを反映
home-manager switch --flake '.#hwata@nixos'

# NixOSを一時反映
sudo nixos-rebuild test --flake '.#nixos'

# NixOSを永続反映
sudo nixos-rebuild switch --flake '.#nixos'
```
