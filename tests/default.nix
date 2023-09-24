{
  self,
  pkgs,
  ...
}: let
  # NixOS module shared between server and client
  sharedModule = {
    users.users.root.password = "";
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    virtualisation.graphics = false;
    networking.firewall.enable = false;
    services.narrowlink = {
      enable = true;
    };
    services.openssh = {
        enable = true;
        settings = {
            PermitRootLogin = "yes";
            PermitEmptyPasswords = "yes";
        };
    };
    programs.ssh.extraConfig = ''
        StrictHostKeyChecking accept-new
    '';
    system.stateVersion = "23.05";
  };
  a="${pkgs.writeText  "aaaa"  (builtins.readFile ./clienta.yaml)}";
  b="${pkgs.writeText  "bbbb"  (builtins.readFile ./clientb.yaml)}";
in
  pkgs.nixosTest {
    name = "basic test";
    skipTypeCheck = true;
    nodes = {
        gateway = {
        config,
        pkgs,
        ...
        }: {
          imports = [
            self.nixosModules.default
            sharedModule
          ];

          services.narrowlink = {
            enable = true;
            gateway = {
                enable = true;
                configFile = "${builtins.readFile ./gateway.yaml}";
            };
          };
        };
        agent = {
        config,
        pkgs,
        ...
        }: {
          imports = [
            self.nixosModules.default
            sharedModule
          ];

          services.narrowlink = {
            enable = true;
            agent = {
                enable = true;
                configFile =    "${builtins.readFile ./agent.yaml}";
            };
          };
        };
        clienta = {
        config,
        pkgs,
        ...
        }: {
          imports = [
            self.nixosModules.default
            sharedModule
          ];
        #   services.narrowlink = {
        #     enable = true;
        #     agent = {
        #         enable = true;
        #         configFile =    "${builtins.readFile ./agent.yaml}";
        #     };
        #   };
        };
        clientb = {
        config,
        pkgs,
        ...
        }: {
          imports = [
            self.nixosModules.default
            sharedModule
          ];
        };
    };
    testScript = {nodes, ...}: ''
        start_all()
        # machine.wait_for_unit("default.target")
        clienta.wait_for_unit("default.target")
        clientb.wait_for_unit("default.target")
        gateway.wait_for_unit("default.target")
        agent.wait_for_unit("narrowlink-agent.service")
        clienta.succeed("ping -c 1 clientb")
        clienta.succeed("ssh -v clientb ls /")
        agent.succeed("systemctl is-active --quiet narrowlink-agent.service")
        clienta.succeed("narrowlink --config=${a} connect -n agent root@clientb:22")
    '';
  }
