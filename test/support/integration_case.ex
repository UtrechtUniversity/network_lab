defmodule NetworkLabWeb.IntegrationCase do
    @moduledoc """
    This module defines the test case to be used by
    ntegration tests.
    """
  
    use ExUnit.CaseTemplate
  
    using do
      quote do
        use Wallaby.DSL
        alias NetworkLab.Repo
        alias NetworkLab.GenServers.Cache
        import Ecto
        import Ecto.Changeset
        import Ecto.Query

        import NetworkLabWeb.Router.Helpers
      end
    end
  
    setup tags do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(NetworkLab.Repo)
  
      unless tags[:async] do
        Ecto.Adapters.SQL.Sandbox.mode(NetworkLab.Repo, {:shared, self()})
      end
  
      metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(NetworkLab.Repo, self())
      { :ok, session } = Wallaby.start_session(metadata: metadata)
      { :ok, session: session }
    end
  end
  