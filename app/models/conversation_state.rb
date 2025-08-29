class ConversationState < ApplicationRecord
  belongs_to :chat

  # Store pending tool names as JSON array of strings
  # Store missing parameters as JSON array of parameter hashes
  # Store collected parameters as JSON hash
  attribute :pending_tool_names, :json, default: []
  attribute :missing_params, :json, default: []
  attribute :collected_params, :json, default: {}

  def set_pending_tools(tools)
    self.pending_tool_names = tools.map(&:name)
    save!
  end

  def pending_tools
    # This method will be overridden by the ConversationManager to provide actual tool objects
    pending_tool_names
  end

  def update_missing_params(params)
    self.missing_params = params
    save!
  end

  def fill_parameter(value)
    return false if missing_params.empty?
    
    param_name = missing_params.first['parameter']
    collected_params[param_name] = value
    
    # Remove all missing parameters with this name
    missing_params.reject! { |param| param['parameter'] == param_name }
    save!
  end

  def clear_pending_tools
    self.pending_tool_names = []
    self.missing_params = []
    self.collected_params = {}
    save!
  end
end
