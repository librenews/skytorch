class RenameLlmProvidersToProviders < ActiveRecord::Migration[8.0]
  def up
    rename_table :llm_providers, :providers
  end

  def down
    rename_table :providers, :llm_providers
  end
end
