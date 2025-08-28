class UsageTrackerService
  # Standard usage data structure that works across providers
  UsageData = Struct.new(:prompt_tokens, :completion_tokens, :total_tokens, :raw_data, keyword_init: true)
  
  # Provider-specific usage extractors
  EXTRACTORS = {
    'openai' => ->(response) {
      usage = response.dig('usage') || response.dig(:usage) || {}
      UsageData.new(
        prompt_tokens: usage['prompt_tokens'] || usage[:prompt_tokens],
        completion_tokens: usage['completion_tokens'] || usage[:completion_tokens],
        total_tokens: usage['total_tokens'] || usage[:total_tokens],
        raw_data: usage
      )
    },
    
    'anthropic' => ->(response) {
      usage = response.dig('usage') || response.dig(:usage) || {}
      UsageData.new(
        prompt_tokens: usage['input_tokens'] || usage[:input_tokens],
        completion_tokens: usage['output_tokens'] || usage[:output_tokens],
        total_tokens: (usage['input_tokens'] || usage[:input_tokens]).to_i + (usage['output_tokens'] || usage[:output_tokens]).to_i,
        raw_data: usage
      )
    },
    
    'google' => ->(response) {
      usage = response.dig('usageMetadata') || response.dig(:usageMetadata) || {}
      UsageData.new(
        prompt_tokens: usage['promptTokenCount'] || usage[:promptTokenCount],
        completion_tokens: usage['candidatesTokenCount'] || usage[:candidatesTokenCount],
        total_tokens: usage['totalTokenCount'] || usage[:totalTokenCount],
        raw_data: usage
      )
    }
  }
  
  def self.extract_usage(provider_type, response)
    extractor = EXTRACTORS[provider_type.to_s.downcase]
    
    if extractor
      extractor.call(response)
    else
      # Fallback for unknown providers
      UsageData.new(
        prompt_tokens: nil,
        completion_tokens: nil,
        total_tokens: nil,
        raw_data: response
      )
    end
  end
  
  def self.calculate_cost(usage_data, provider_type, model = nil)
    return 0 unless usage_data&.total_tokens
    
    pricing = get_pricing(provider_type, model)
    
    prompt_cost = (usage_data.prompt_tokens || 0) * pricing[:prompt_per_1k] / 1000.0
    completion_cost = (usage_data.completion_tokens || 0) * pricing[:completion_per_1k] / 1000.0
    
    prompt_cost + completion_cost
  end
  
  private
  
  def self.get_pricing(provider_type, model = nil)
    case provider_type.to_s.downcase
    when 'openai'
      case model
      when 'gpt-4o', 'gpt-4o-mini'
        { prompt_per_1k: 0.005, completion_per_1k: 0.015 }
      when 'gpt-4-turbo'
        { prompt_per_1k: 0.01, completion_per_1k: 0.03 }
      when 'gpt-3.5-turbo'
        { prompt_per_1k: 0.0005, completion_per_1k: 0.0015 }
      else
        { prompt_per_1k: 0.005, completion_per_1k: 0.015 } # Default to GPT-4o pricing
      end
    when 'anthropic'
      case model
      when 'claude-3-5-sonnet-20241022'
        { prompt_per_1k: 0.003, completion_per_1k: 0.015 }
      when 'claude-3-opus-20240229'
        { prompt_per_1k: 0.015, completion_per_1k: 0.075 }
      when 'claude-3-sonnet-20240229'
        { prompt_per_1k: 0.003, completion_per_1k: 0.015 }
      else
        { prompt_per_1k: 0.003, completion_per_1k: 0.015 } # Default to Claude-3.5 Sonnet pricing
      end
    when 'google'
      case model
      when 'gemini-1.5-flash'
        { prompt_per_1k: 0.000075, completion_per_1k: 0.0003 }
      when 'gemini-1.5-pro'
        { prompt_per_1k: 0.00375, completion_per_1k: 0.015 }
      else
        { prompt_per_1k: 0.000075, completion_per_1k: 0.0003 } # Default to Gemini 1.5 Flash pricing
      end

    else
      { prompt_per_1k: 0.001, completion_per_1k: 0.003 } # Generic fallback pricing
    end
  end
end
