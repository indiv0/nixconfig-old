let
  pkgs = import <nixpkgs> { };
  deploy = pkgs.writeScriptBin "deploy" ''
    #!${pkgs.stdenv.shell}
    set -o pipefail
    set -o xtrace

    function deploy() {
      ${pkgs.rsync}/bin/rsync --archive --verbose --hard-links --xattrs --sparse \
        --human-readable --partial --progress --protect-args --exclude '.*' \
        data.nix shell.nix hosts modules deploy@$1:/etc/nixos/
    }

    deploy "$@"
  '';
in
pkgs.mkShell {
  buildInputs = [
    deploy

    pkgs.niv
    pkgs.nixpkgs-fmt
  ];
}
