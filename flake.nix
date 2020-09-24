{
  description = "Tektonix - tekton pipelines using Nix";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nix-misc = {
    url = "github:johnae/nix-misc";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ inputs.nix-misc.overlay ];
          };
          defaultPackage = pkgs.writeStrictShellScriptBin "tektonix" ''
            pipelinePath=''${1:-}
            if [ -z "$pipelinePath" ]; then
              echo Please provide the path to a pipeline as the only argument
              exit 1
            fi
            pipelinePath="$(realpath "$pipelinePath")"
            if [ ! -e "$pipelinePath" ]; then
              echo "$pipelinePath" does not exist
              exit 1
            fi
            pipelineName=''${2:-"$(basename "$pipelinePath" .nix)"}
            cd ${self}
            ${pkgs.nixUnstable}/bin/nix eval --json --impure --expr \
                 "import ./. { pkgs = import ${pkgs.path} { }; pipelinePath = $pipelinePath; name = \"$pipelineName\"; }"
          '';
        in
        {
          inherit defaultPackage;
          packages = flake-utils.lib.flattenTree {
            tektonix = defaultPackage;
          };
          apps.tektonix = flake-utils.lib.mkApp { drv = defaultPackage; };
          defaultApp = defaultPackage;
        }
      );
}
