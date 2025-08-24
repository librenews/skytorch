class CreateLlmProviders < ActiveRecord::Migration[8.0]
  def change
    create_table :llm_providers do |t|
      t.string :name
      t.string :provider_type
      t.string :api_key
      t.string :base_url
      t.string :default_model
      t.boolean :is_active

      t.timestamps
    end
  end
end
