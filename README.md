# ❄️ nixcfg

This flake is my all-in-one Nix configuration. It manages both my local clients and infrastructure servers.

It defines:

- My home cluster
  - [dray](/machines/dray)
  - [shai](/machines/shai)
  - [luka](/machines/luka)
- My Oracle Cloud VMs
  - [bird](/machines/bird)
- My local dev VMs
  - [butler](/machines/butler)
- My Macbook
  - [ant](/machines/ant)

It is formatted as a collection of [`flake-parts`](https://flake.parts/) modules, and managed with [`clan`](https://clan.lol/).

For a rough idea of the resulting server infrastructure, see the generated [topology diagram](https://raw.githubusercontent.com/benkoppe/nixcfg/refs/heads/clan/docs/topology/main.png).

### Details

- All dotfiles are managed with [hjem](https://github.com/feel-co/hjem)
- Most services are run in isolated [microVMs](https://github.com/microvm-nix/microvm.nix)
  - Less-important Docker services are run in vm-komodo using [komodo-syncs](https://github.com/benkoppe/komodo-syncs)
- When applicable, terraform is defined using [terranix](https://github.com/terranix/terranix) in `terranix.nix` files.
