{
  description = "An Elixir development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";

    # Elixir
    elixir.url = "github:elixir-lang/elixir?ref=v1.13.2";
    elixir.flake = false;

    # Erlang
    erlang.url = "github:erlang/otp?ref=OTP-24.2.1";
    erlang.flake = false;

    # ElixirLS
    elixir_ls.url = "github:elixir-lsp/elixir-ls?ref=v0.9.0";
    elixir_ls.flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, elixir, erlang, elixir_ls }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ ];
        };

        erlang_custom = pkgs.erlang.overrideAttrs (oldAttrs: rec {
          version = "24.2.1";
          name = "erlang-${version}";
          src = erlang;

          configureFlags = oldAttrs.configureFlags
            ++ [ "--with-ssl=${pkgs.lib.getOutput "out" pkgs.openssl}" ] ++ [
              "--with-ssl-incl=${pkgs.lib.getDev pkgs.openssl}"
            ]; # This flag was introduced in R24
        });

        elixir_custom = pkgs.elixir.overrideAttrs (oldAttrs: rec {
          version = "1.13.2";
          name = "elixir-${version}";
          src = elixir;

          buildInputs = [ erlang_custom ];
          nativeBuildInputs = oldAttrs.nativeBuildInputs or [ ]
            ++ [ pkgs.makeWrapper ];
        });

        # Note: The tagged 0.9.0 version of ElixirLS says its version is 0.8.2
        # on start.
        elixir_ls_custom = pkgs.elixir_ls.overrideAttrs (oldAttrs: rec {
          version = "0.9.0";
          name = "elixir-ls-${version}";
          src = elixir_ls;

          buildInputs = [ elixir_custom ];
        });

        beamPkgs = pkgs.beam.packagesWith erlang_custom;

        devShell = pkgs.mkShell {
          buildInputs = [
            elixir_custom
            erlang_custom
            elixir_custom
            beamPkgs.hex
            beamPkgs.rebar
            beamPkgs.rebar3
            pkgs.cmake
            pkgs.glibcLocales
            pkgs.inotify-tools
            pkgs.libgit2
            pkgs.nodejs
            pkgs.zlib
          ];

          shellHook = ''
            unset ERL_LIBS

            export C_INCLUDE_PATH=${erlang_custom}/lib/erlang/usr/include
            export LANG="en_US.UTF-8"
            export LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive
            export MIX_REBAR3=${beamPkgs.rebar3}/bin/rebar3
            export MIX_REBAR=${beamPkgs.rebar}/bin/rebar
          '';
        };
      in {
        inherit devShell;
        packages.elixir = elixir_custom;
        packages.erlang = erlang_custom;
        packages.elixir_ls = elixir_ls_custom;
        defaultPackage = elixir_custom;
      });
}
