{ pkgs
, pipelinePath
, name ? (builtins.head (
    builtins.split "(\.nix$)"
      (builtins.baseNameOf pipelinePath)
  ))
, extraConfigJson ? "{}"
, specialArgs ? { }
}:
let

  sanitize =
    with pkgs;
    with pkgs.lib;
    configuration:
    builtins.getAttr (builtins.typeOf configuration) {
      bool = configuration;
      int = configuration;
      string = configuration;
      list = map sanitize configuration;
      set = mapAttrs
        (const sanitize)
        (filterAttrs (name: value: name != "_module" && value != null) configuration);
    };

  modules = with pkgs.lib;
    mapAttrsToList
      (name: _: ./modules + "/${name}")
      (
        filterAttrs
          (name: _: hasSuffix ".nix" name)
          (builtins.readDir ./modules)
      )
  ;

  result =
    pkgs.lib.evalModules {
      modules = modules ++ [
        pipelinePath
      ];
      args = {
        inherit pkgs name;
        config = result.config;
        lib = pkgs.lib;
        extraConfig = builtins.fromJSON extraConfigJson;
      };
      inherit specialArgs;
    };

  resources = with pkgs.lib;
    (filterAttrs
      (name: _:
        name == "tasks" ||
        name == "pipelines" ||
        name == "taskRuns" ||
        name == "pipelineRuns"
      )
      (sanitize result.config).resources);
in
{
  kind = "List";
  apiVersion = "v1";
  items = resources.tasks ++
    resources.pipelines ++
    resources.taskRuns ++
    resources.pipelineRuns;
}
