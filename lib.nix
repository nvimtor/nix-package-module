{ name, nix-common, ... }:
{ lib, config, ... }: let
  lib' = lib.extend nix-common.overlays.lib;
in {
  options.${name}.lib = lib.mkOption {
    type = lib.types.attrs;
    default = {};
  };

  config.${name}.lib = let
    self = config.${name}.lib;
  in {
    pkg = f: {
      _tag = "callPackageable";
      val = f;
    };

    input = x: {
      _tag = "packageScopeInput";
      val = x;
    };

    importPackages = dir: lib.pipe dir [
      lib'.importDirectory
      (lib.mapAttrs (_: self.pkg))
    ];
  };
}
