{
  flake.modules.nixos."microvms_client_nix-store-share" = {
    microvm.shares = [
      {
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "virtiofs";
      }
    ];
  };
}
