class ToolService
  def initialize(user = nil)
    @user = user
  end
  
  def create_tool(params)
    tool = Tool.new(params)
    tool.user = @user if @user
    tool.save
    tool
  end
  
  def import_from_lexicon(lexicon_record)
    return nil unless @user
    
    # Extract owner DID and find or create user
    owner_did = lexicon_record["owner"]
    owner_user = User.find_by(bluesky_did: owner_did)
    
    # If it's a public tool and we don't own it, create a copy in our toolbox
    if lexicon_record["visibility"] == "public" && owner_user != @user
      tool = Tool.from_lexicon_record(lexicon_record, @user)
      tool.visibility = "private" # Make it private in our toolbox
      tool.save
      return tool
    end
    
    # Otherwise, create normally
    Tool.from_lexicon_record(lexicon_record, @user)
  end
  
  def search_tools(query, options = {})
    Tool.search(query, options.merge(user: @user))
  end
  
  def discover_tools(query, options = {})
    # Search public tools from all users
    Tool.search(query, options.merge(scope: 'public'))
  end
  
  def recommend_tools(user_tools, limit = 10)
    # TODO: Implement recommendation algorithm using embeddings
    # For now, return popular public tools
    Tool.public_tools.order(created_at: :desc).limit(limit)
  end
end



