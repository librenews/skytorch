class CreateMcpServers < ActiveRecord::Migration[8.0]
  def change
    create_table :mcp_servers do |t|
      t.string :name
      t.string :url
      t.text :description

      t.timestamps
    end
  end
end
