{
  description = "A collection of nix flake templates";

  outputs = { self }: {
    elixir-dev-env = {
      path = ./elixir-dev-env;
      description = "An Elixir development environment";
    };
  };
}
