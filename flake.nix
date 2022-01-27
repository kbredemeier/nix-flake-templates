{
  description = "A collection of nix flake templates";

  outputs = { self }: {
    templates = {
      elixir-phx-dev-env = {
        path = ./elixir-phx-dev-env;
        description = "A development environment for Elixir Phoenix projects";
      };
    };
  };
}
