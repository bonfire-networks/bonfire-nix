# 🚀 One-Click NixOS Install on Hetzner Cloud

## Quick Start (for Beginners)

1. **Create a Hetzner Cloud server**
   - Choose Ubuntu or Debian as the OS (default is fine) and configure IPv4.
   - Note the server's IP address from the Hetzner dashboard

2. **On your Mac or Linux computer:**
   - Open Terminal
   - Run `nix run --extra-experimental-features 'nix-command flakes' github:nix-community/nixos-anywhere -- --flake ~/Desktop/Code/bonfire-nix#nixos-vm --target-host root@<Hetzner Cloud IP address> --build-on-remote`

---

# `bonfire-nix`

A Nix flake providing NixOS modules for [Bonfire](https://bonfirenetworks.org/) provisioning.

## Join our community

If you have questions about anything related to Bonfire, you're always welcome to ask our community on [Matrix](https://matrix.to/#/#bonfire-networks:matrix.org), [Slack](https://join.slack.com/t/elixir-lang/shared_invite/zt-2ko4792lz-28XosraCTaYZKOyuZ80hrg), [Elixir Forum](https://elixirforum.com) and the [Fediverse](https://indieweb.social/@bonfire) or send us an email at team@bonfire.cafe.

## Copyright and License

Copyright (c) 2025 Bonfire Contributors

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public
License along with this program.  If not, see <https://www.gnu.org/licenses/>.
