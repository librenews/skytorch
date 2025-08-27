class ChangeChatStatusToString < ActiveRecord::Migration[8.0]
  def up
    # First, add a temporary string column
    add_column :chats, :status_string, :string
    
    # Update existing data to map integer values to strings
    execute <<-SQL
      UPDATE chats 
      SET status_string = CASE status 
        WHEN 0 THEN 'active'
        WHEN 1 THEN 'archived' 
        WHEN 2 THEN 'reported'
        ELSE 'active'
      END
    SQL
    
    # Remove the old integer column
    remove_column :chats, :status
    
    # Rename the new string column to status
    rename_column :chats, :status_string, :status
    
    # Add an index on the status column for better performance
    add_index :chats, :status
  end

  def down
    # Add a temporary integer column
    add_column :chats, :status_integer, :integer
    
    # Update existing data to map strings back to integers
    execute <<-SQL
      UPDATE chats 
      SET status_integer = CASE status 
        WHEN 'active' THEN 0
        WHEN 'archived' THEN 1
        WHEN 'reported' THEN 2
        ELSE 0
      END
    SQL
    
    # Remove the string column
    remove_column :chats, :status
    
    # Rename the integer column to status
    rename_column :chats, :status_integer, :status
    
    # Remove the index
    remove_index :chats, :status
  end
end
