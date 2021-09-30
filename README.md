# nixconfig

My collection of Nix configuration files. This repo is heavily inspired by
https://github.com/etu/nixconfig.

To make the `deploy` command available, run `nix-shell`. This will initialize
the Nix shell described in `shell.nix`.

Use the `deploy` command to copy over the files in this repo to the target
host:

```sh
deploy lab-ca-kvm-01
```

Then SSH into the host and apply the new configuration:

```sh
ssh deploy@lab-ca-kvm-01 sudo nixos-rebuild switch
```
