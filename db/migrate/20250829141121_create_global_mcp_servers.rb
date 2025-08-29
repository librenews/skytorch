class CreateGlobalMcpServers < ActiveRecord::Migration[8.0]
  def change
    create_table :global_mcp_servers do |t|
      t.string :name
      t.string :transport_type
      t.jsonb :config
      t.boolean :is_active

      t.timestamps
    end
  end
end
