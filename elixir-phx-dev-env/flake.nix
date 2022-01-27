{
  description = "An Elixir Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ ];
        };
        erlangVersion = "erlangR25";
        elixirVersion = "elixir_1_14";

        erlang = pkgs.beam.interpreters.${erlangVersion};
        elixir = pkgs.beam.packages.${erlangVersion}.${elixirVersion};
        elixir_ls = pkgs.beam.packages.${erlangVersion}.elixir-ls;

        inherit (pkgs.lib) optional optionals;

        fileWatchers = with pkgs;
          (optional stdenv.isLinux inotify-tools ++ optionals stdenv.isDarwin
            (with darwin.apple_sdk.frameworks; [
              CoreFoundation
              CoreServices
            ]));

        beamPkgs = pkgs.beam.packages.${erlangVersion};

        devShell = pkgs.mkShell {
          name = "elixir-dev-env";
          buildInputs = [ erlang elixir elixir_ls ] ++ [
            beamPkgs.hex
            beamPkgs.rebar
            beamPkgs.rebar3
            pkgs.cacert
            pkgs.cmake
            pkgs.glibcLocales
            pkgs.inotify-tools
            pkgs.jmespath
            pkgs.libgit2
            pkgs.libxml2
            pkgs.nodejs
            pkgs.nodePackages.sass
            pkgs.zip
            pkgs.zlib
          ] ++ fileWatchers;

          C_INCLUDE_PATH = "${erlang}/lib/erlang/usr/include";
          ERL_AFLAGS = "-kernel shell_history enabled";
          LANG = "en_US.UTF-8";
          LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
          MIX_REBAR3 = "${beamPkgs.rebar3}/bin/rebar3";
          MIX_REBAR = "${beamPkgs.rebar}/bin/rebar";

          shellHook = ''
            mkdir .nix-hex 2> /dev/null
            mkdir .nix-mix 2> /dev/null

            unset ERL_LIBS
            export HEX_HOME=$PWD/.nix-hex
            export MIX_HOME=$PWD/.nix-mix
            export PATH=$HEX_HOME/bin:$PATH
            export PATH=$MIX_HOME/escripts:$PATH
          '';
        };
      in
      {
        inherit devShell;
        packages.elixir = elixir;
        packages.erlang = erlang;
        packages.elixir_ls = elixir_ls;
        packages.default = devShell;
      });
}
