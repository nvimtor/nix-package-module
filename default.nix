{ name ? "nix-package-module",
  extraInputs ? {},
  nix-common,
  ...
}:
{ pkgs, config, ... }: let
  inherit (pkgs) newScope;

  lib = pkgs.lib.extend nix-common.overlays.lib;

  inherit (lib) makeScope mkOption types;

  isCallPackageable = x: (x ? "_tag") && x._tag == "callPackageable";

  isPackageScopeInput = x: (x ? "_tag") && x._tag == "packageScopeInput";

  buildTree = scope: branch: makeScope scope (self: let
    inherit (self) callPackage;
  in if !lib.isAttrs branch
  then callPackage branch { }
  else lib.foldlAttrs (acc: k: v: acc // { ${k} =
    if isPackageScopeInput v then v.val
    else if isCallPackageable v then callPackage v.val { }
    else if lib.isDerivation v then v
    else if lib.isAttrs v then buildTree (s: self.newScope (s // self)) v
    else callPackage v { };
  }) extraInputs branch);
in {
  imports = [
    (import ./lib.nix { inherit name nix-common; })
  ];

  options.${name} = {
    packages = mkOption {
      type = types.attrs;
      default = {};
    };

    packageOutputs = mkOption {
      type = types.lazyAttrsOf types.raw;
      readOnly = true;
      default = buildTree newScope config.${name}.packages;
    };
  };
}
