{ config, ... }:

let
  homeSubnet = "192.168.0.24/24";
in
{
  networking.nftables.enable = true;

  networking.firewall.extraInputRules = ''
    ip saddr ${homeSubnet} tcp dport 22 accept
    iifname "${config.services.tailscale.interfaceName}" tcp dport 22 accept
  '';

  services.openssh = {
    enable = true;
    openFirewall = false;

    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ "hwata" ];
    };
  };

  users.users.hwata.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPg62tkYqmWIUoHyroTwQ3hIvGdfrfcTWmpDT8QyZHF5 laptop-to-nixos"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINghob82c3fhw6Xe200GZSgNgpqSv1CE5zIzGSM+m37s" #smartphone(oppo)2nixos
  ];
}
