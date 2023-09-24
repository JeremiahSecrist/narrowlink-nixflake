{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkMerge mkIf mkDoc types;
  gatewayConfig = "${pkgs.writeText "narrowlink-gateway-config" cfg.gateway.configFile}";
  agentConfig = "${pkgs.writeText "narrowlink-agent-config" cfg.agent.configFile}";
  cfg = config.services.narrowlink;
in {
  options = {
    services = {
      narrowlink = {
        enable = mkEnableOption (mkDoc "enables narrowlink services");
        gateway = {
          enable = mkEnableOption (mkDoc "enables narrowlink gateway services");
          configFile = mkOption {
            type = types.lines;
          };
        };
        agent = {
          enable = mkEnableOption (mkDoc "enables narrowlink gateway services");
          configFile = mkOption {
            type = types.lines;
          };
        };
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        narrowlink
      ];
    })
    (mkIf (cfg.enable && cfg.gateway.enable) {
      systemd.services.narrowlink-gateway = {
        description = "gateway service for narrowlink";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        serviceConfig = {
          DynamicUser = true;
          ExecStart = "${pkgs.narrowlink}/bin/narrowlink-gateway --config=${gatewayConfig}";
          Restart = "on-failure";
          AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
          CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE"];
        };
      };
    })
    (mkIf (cfg.enable && cfg.agent.enable) {
      systemd.services.narrowlink-agent = {
        description = "agent service for narrowlink";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        serviceConfig = {
          DynamicUser = true;
          ExecStart = "${pkgs.narrowlink}/bin/narrowlink-agent --config=${agentConfig}";
          Restart = "on-failure";
          AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
          CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE"];
        };
      };
    })
  ];
}
