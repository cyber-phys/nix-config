{ inputs, pkgs, ... }:
let
  toDateTime = timestamp: builtins.readFile (
    pkgs.runCommandLocal "datetime" { } ''
      dt="$(date -Ru -d @${toString timestamp})"
      echo -n ''${dt/+0000/GMT} > $out
    ''
  );
in
{
  services = {
    nginx.virtualHosts = {
      "misterio.me" = {
        default = true;
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          root = "${pkgs.website.main}/public";
          extraConfig = ''
            add_header Last-Modified "${toDateTime inputs.website.lastModified}";
          '';
        };
      };
      "fontes.dev.br" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          return = "302 https://misterio.me$request_uri";
        };
      };
    };
    # Gemini
    agate = {
      enable = true;
      contentDir = "${pkgs.website.main}/public";
      hostnames = [ "misterio.me" ];
    };
  };
  networking.firewall.allowedTCPPorts = [ 1965 ];
}
