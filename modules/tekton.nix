{ config, lib, ... }:
with lib;
let

  attrValueToList = value:
    if value == null then null
    else
      lib.mapAttrsToList
        (name: value:
          { inherit name; } // value)
        value;

  tasksModule = types.submodule
    ({ config, name, ... }: {
      options = {
        apiVersion = mkOption {
          type = types.str;
          default = "tekton.dev/v1beta1";
        };
        kind = mkOption {
          type = types.str;
          default = "Task";
        };
        metadata = mkOption {
          type = types.attrs;
          apply = v: { inherit name; } // v;
          default = { inherit name; };
        };
        spec = mkOption {
          type = types.submodule {
            options = {
              params = mkOption {
                type = types.nullOr (types.attrsOf types.attrs);
                default = null;
                apply = attrValueToList;
              };
              results = mkOption {
                type = types.nullOr (types.listOf (types.submodule {
                  options = {
                    name = mkOption {
                      type = types.str;
                    };
                    description = mkOption {
                      type = types.nullOr types.str;
                      default = null;
                    };
                  };
                }));
                default = null;
              };
              steps = mkOption {
                type = types.listOf types.attrs;
              };
              sidecars = mkOption {
                type = types.nullOr (types.listOf types.attrs);
                default = null;
              };
              volumes = mkOption {
                type = types.nullOr (types.attrsOf types.attrs);
                default = null;
                apply = attrValueToList;
              };
            };
          };
        };
      };
    });

  taskRunsModule = types.submodule
    ({ config, name, ... }: {
      options = {
        apiVersion = mkOption {
          type = types.str;
          default = "tekton.dev/v1beta1";
        };
        kind = mkOption {
          type = types.str;
          default = "TaskRun";
        };
        metadata = mkOption {
          type = types.attrs;
          apply = v:
            if builtins.hasAttr "name" v then v
            else { generateName = "${name}-"; } // v;
          default = { generateName = "${name}-"; };
        };
        spec = mkOption {
          type = types.submodule {
            options = {
              taskRef = mkOption {
                type = types.submodule {
                  options = {
                    name = mkOption { type = types.str; };
                  };
                };
              };
              params = mkOption {
                type = types.nullOr (types.attrsOf types.attrs);
                default = null;
                apply = attrValueToList;
              };
              serviceAccountName = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              timeout = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              podTemplate = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
            };
          };
        };
      };
    });

  pipelineTasksModule = types.submodule ({ config, name, ... }: {
    options = {
      taskRef = mkOption {
        type = types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              default = name;
            };
          };
        };
      };
      runAfter = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
      };
      params = mkOption {
        type = types.nullOr (types.attrsOf types.attrs);
        default = null;
        apply = attrValueToList;
      };
    };
  });

  pipelinesModule = types.submodule
    ({ config, name, ... }: {
      options = {
        apiVersion = mkOption {
          type = types.str;
          default = "tekton.dev/v1beta1";
        };
        kind = mkOption {
          type = types.str;
          default = "Pipeline";
        };
        metadata = mkOption {
          type = types.attrs;
          apply = v: { inherit name; } // v;
          default = { inherit name; };
        };
        spec = mkOption {
          type = types.submodule {
            options = {
              params = mkOption {
                type = types.nullOr (types.attrsOf types.attrs);
                default = null;
                apply = attrValueToList;
              };
              results = mkOption {
                type = types.nullOr (types.listOf (types.submodule {
                  options = {
                    name = mkOption {
                      type = types.str;
                    };
                    value = mkOption {
                      type = types.str;
                    };
                    description = mkOption {
                      type = types.nullOr types.str;
                      default = null;
                    };
                  };
                }));
                default = null;
              };
              tasks = mkOption {
                type = types.nullOr (types.attrsOf pipelineTasksModule);
                apply = attrValueToList;
                default = null;
              };
            };
          };
        };
      };
    });

  pipelineRunsModule = types.submodule
    ({ config, name, ... }: {
      options = {
        apiVersion = mkOption {
          type = types.str;
          default = "tekton.dev/v1beta1";
        };
        kind = mkOption {
          type = types.str;
          default = "PipelineRun";
        };
        metadata = mkOption {
          type = types.attrs;
          apply = v:
            if builtins.hasAttr "name" v then v
            else { generateName = "${name}-"; } // v;
          default = { generateName = "${name}-"; };
        };
        spec = mkOption {
          type = types.submodule {
            options = {
              pipelineRef = mkOption {
                type = types.submodule {
                  options = {
                    name = mkOption { type = types.str; };
                  };
                };
              };
              params = mkOption {
                type = types.nullOr (types.attrsOf types.attrs);
                default = null;
                apply = attrValueToList;
              };
              serviceAccountName = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              timeout = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              podTemplate = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
            };
          };
        };
      };
    });

in
{
  options.resources = {
    tasks = mkOption {
      type = types.attrsOf tasksModule;
      default = { };
      apply = lib.mapAttrsToList (_: v: v);
    };
    taskRuns = mkOption {
      type = types.attrsOf taskRunsModule;
      default = { };
      apply = lib.mapAttrsToList (_: v: v);
    };
    pipelines = mkOption {
      type = types.attrsOf pipelinesModule;
      default = { };
      apply = lib.mapAttrsToList (_: v: v);
    };
    pipelineRuns = mkOption {
      type = types.attrsOf pipelineRunsModule;
      default = { };
      apply = lib.mapAttrsToList (_: v: v);
    };
  };
}
