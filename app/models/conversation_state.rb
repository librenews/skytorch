class ConversationState < ApplicationRecord
  belongs_to :chat
  
  validates :status, presence: true, inclusion: { in: %w[normal collecting_params executing_tools] }
  
  # Default values for JSONB fields
  attribute :pending_tools, :json, default: []
  attribute :missing_params, :json, default: []
  attribute :collected_params, :json, default: {}
  attribute :tool_results, :json, default: []
  
  def fill_parameter(value)
    return false if missing_params.empty?
    
    # Fill the first missing parameter
    param_to_fill = missing_params.first
    collected_params[param_to_fill['parameter']] = value
    missing_params.shift
    
    save!
  end
  
  def all_parameters_filled?
    missing_params.empty?
  end
  
  def clear_state
    update!(
      status: 'normal',
      pending_tools: [],
      missing_params: [],
      collected_params: {},
      original_message: nil,
      tool_results: []
    )
  end
  
  def remove_failed_tool(tool_name)
    pending_tools.reject! { |tool| tool['name'] == tool_name }
    save!
  end
  
  def add_tool_result(tool_name, result)
    tool_results << {
      tool: tool_name,
      content: result,
      timestamp: Time.current
    }
    save!
  end
end
