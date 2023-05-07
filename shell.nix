{ sources ? import ./nix/sources.nix
, pkgs ? import sources.nixpkgs { }
}:

with pkgs;
let
  inherit (lib) optional optionals;
  basePackages = [
    (import ./nix/default.nix { inherit pkgs; })
    pkgs.niv
    nixpkgs-fmt
    fswatch
    gcc
    ack
  ];

  inputs = basePackages ++ lib.optionals stdenv.isLinux [ inotify-tools ]
    ++ lib.optionals stdenv.isDarwin
    (with darwin.apple_sdk.frameworks; [ CoreFoundation CoreServices Foundation AppKit ]);

  # define shell startup command
  hooks = ''
    # this allows mix to work on the local directory
    mkdir -p .nix-mix .nix-hex
    export MIX_HOME=$PWD/.nix-mix
    export HEX_HOME=$PWD/.nix-hex

    # make hex from Nixpkgs available
    # `mix local.hex` will install hex into MIX_HOME and should take precedence
    export MIX_PATH="${beam.packages.erlangR25.hex}/lib/erlang/lib/hex/ebin"
    export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH
    export LANG=C.UTF-8
    export LC_CTYPE=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

    # keep your shell history in iex
    export ERL_AFLAGS="-kernel shell_history enabled"

    export PATH=bin:$PATH
    export MIX_ENV=dev
  '';

in
mkShell {
  buildInputs = inputs;
  shellHook = hooks;

  ####################################################################
  # Without  this, almost  everything  fails with  locale issues  when
  # using `nix-shell --pure` (at least on NixOS).
  # See
  # + https://github.com/NixOS/nix/issues/318#issuecomment-52986702
  # + http://lists.linuxfromscratch.org/pipermail/lfs-support/2004-June/023900.html
  ####################################################################
  LOCALE_ARCHIVE = if pkgs.stdenv.isLinux then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
}
