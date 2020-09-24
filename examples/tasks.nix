## create the pipeline using tektonix
## from https://github.com/johnae/tektonix
{ config, pkgs, lib, name, ... }:

let
  securityContext = {
    runAsUser = 999;
    runAsGroup = 999;
    allowPrivilegeEscalation = false;
  };
  workingDir = "/home/robot";
  env = [
    { name = "NIX_REMOTE"; value = "daemon"; }
    { name = "USER"; value = "robot"; }
    { name = "HOME"; value = workingDir; }
  ];
  envFrom = [
    {
      secretRef.name = "default-env";
    }
  ];
  volumeMounts = [
    { name = "home"; mountPath = "/home/robot"; }
    { name = "nix"; subPath = "nix"; mountPath = "/nix"; readOnly = true; }
    { name = "nix"; subPath = "etc/nix"; mountPath = "/etc/nix"; readOnly = true; }
    { name = "nix"; subPath = "etc/passwd"; mountPath = "/etc/passwd"; readOnly = true; }
    { name = "nix"; subPath = "var/run"; mountPath = "/var/run"; }
  ];

in
{
  resources.tasks.default.spec = {
    volumes.home = { emptyDir = { }; };
    volumes.nix = { hostPath.path = "/var/nix-container"; };
    params = {
      giturl = { type = "string"; };
      gitrev = { type = "string"; };
      command = { type = "string"; };
    };
    steps = {
      git-clone = {
        inherit securityContext workingDir env envFrom volumeMounts;
        image = "nixpkgs/nix-unstable:latest";
        command = [ "bash" "-c" ];
        args = [
          ''
            exec 2>&1
            set -euo pipefail

            show() {
              echo "$@"
              "$@"
            }

            out="$(basename $(params.giturl) .git)"
            echo cloning repository $(params.giturl) to "$out"

            show nix shell nixpkgs#git -c git clone $(params.giturl) "$out"
            show cd "$out"
            show nix shell nixpkgs#git -c git checkout $(params.gitrev)
          ''
        ];
      };
      build = {
        inherit securityContext workingDir env envFrom volumeMounts;
        image = "nixpkgs/nix-unstable:latest";
        command = [ "bash" "-c" ];
        args = [
          ''
            exec 2>&1
            set -euo pipefail

            show() {
              echo "$@"
              "$@"
            }

            out="$(basename $(params.giturl) .git)"
            show cd "$out"
            $(params.command)
          ''
        ];
      };
    };
  };

}
