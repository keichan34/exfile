# Exfile

File upload handling in Elixir and Plug. Inspired heavily by [Refile](https://github.com/refile/refile).
If you use Ruby, check Refile out. I like it. A lot. 👍

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add exfile to your list of dependencies in `mix.exs`:

        def deps do
          [{:exfile, "~> 0.0.1"}]
        end

  2. Ensure exfile is started before your application:

        def application do
          [applications: [:exfile]]
        end
