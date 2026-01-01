{
  flake.modules.nixos."microvms_client_nix_store_share" = {
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
