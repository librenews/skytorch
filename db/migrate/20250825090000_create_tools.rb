class CreateTools < ActiveRecord::Migration[8.0]
  def change
    create_table :tools do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :tool_type, null: false # tool, resource, prompt
      t.string :visibility, default: 'private' # public, private, unlisted
      t.text :tags, array: true, default: []
      t.jsonb :definition, null: false, default: {}
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      
      # Add indexes for search and performance
      t.index :tool_type
      t.index :visibility
      t.index :tags, using: 'gin'
      t.index :definition, using: 'gin'
      t.index [:user_id, :visibility]
      t.index [:tool_type, :visibility]
    end
  end
end
