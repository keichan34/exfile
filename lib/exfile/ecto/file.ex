if Code.ensure_loaded?(Ecto) do

defmodule Exfile.Ecto.File do
  use Exfile.Ecto.FileTemplate, backend: "store"
end

end
