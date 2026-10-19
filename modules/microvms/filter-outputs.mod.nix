{ lib, ... }:
{
  # vm-* Clan machines are templates completed by microvm.vms on each host.
  # Keep them in Clan for vars and moduleForMachine, but do not advertise them
  # as standalone systems for nix flake check or nixos-rebuild.
  options.flake.nixosConfigurations = lib.mkOption {
    apply = lib.filterAttrs (name: _: !lib.hasPrefix "vm-" name);
  };
}
