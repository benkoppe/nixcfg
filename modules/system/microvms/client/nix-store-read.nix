{
  # implements https://microvm-nix.github.io/microvm.nix/shares.html#sharing-a-hosts-nixstore
  flake.modules.nixos."microvms_client_nix-store-read" = {
    microvm.shares = [
      {
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "virtiofs";
        readOnly = true;
      }
    ];
  };
}
