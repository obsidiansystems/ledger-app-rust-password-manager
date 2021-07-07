rec {
  ledger-platform = import ./dep/ledger-platform {};

  inherit (ledger-platform)
    lib
    pkgs ledgerPkgs
    crate2nix
    buildRustCrateForPkgsLedger;

  shell = lib.overrideDerivation ledger-platform.rustShell (_: {
    LIBCLANG_PATH = ledgerPkgs.buildPackages.llvmPackages.clang-unwrapped.lib + "/lib";
  });

  app = import ./Cargo.nix {
    pkgs = ledgerPkgs;
    buildRustCrateForPkgs = pkgs: (buildRustCrateForPkgsLedger pkgs).override {
      defaultCrateOverrides = pkgs.defaultCrateOverrides // {
        nanos_sdk = _: {
          RUSTC_BOOTSTRAP = true;
        };
        nanopass = attrs: let
          sdk = lib.findFirst (p: lib.hasPrefix "rust_nanos_sdk" p.name) (builtins.throw "no sdk!") attrs.dependencies;
        in {
          preHook = ledger-platform.gccLibsPreHook;
          extraRustcOpts = [
            "-C" "relocation-model=ropi"
            "-C" "link-arg=-T${sdk.lib}/lib/nanos_sdk.out/script.ld"
          ];
        };
      };
    };
  };
}
