require 'ruby_llm'

class LlmClientService
  def initialize(provider)
    @provider = provider
    @client = create_client
  end

  def generate_response(messages, model = nil)
    model ||= @provider.default_model
    
    case @provider.provider_type
    when 'openai'
      generate_openai_response(messages, model)
    when 'anthropic'
      generate_anthropic_response(messages, model)
    when 'google'
      generate_google_response(messages, model)
    when 'mock'
      generate_mock_response(messages)
    else
      raise "Unsupported provider type: #{@provider.provider_type}"
    end
  end

  def generate_response_with_tools(messages, tools = [], model = nil)
    model ||= @provider.default_model
    
    case @provider.provider_type
    when 'openai'
      generate_openai_response_with_tools(messages, tools, model)
    when 'anthropic'
      generate_anthropic_response_with_tools(messages, tools, model)
    when 'google'
      generate_google_response_with_tools(messages, tools, model)
    when 'mock'
      generate_mock_response_with_tools(messages, tools)
    else
      raise "Unsupported provider type: #{@provider.provider_type}"
    end
  end

  private

  def create_client
    case @provider.provider_type
    when 'openai'
      RubyLLM::Client.new(
        provider: :openai,
        api_key: @provider.api_key,
        model: @provider.default_model
      )
    when 'anthropic'
      RubyLLM::Client.new(
        provider: :anthropic,
        api_key: @provider.api_key,
        model: @provider.default_model
      )
    when 'google'
      RubyLLM::Client.new(
        provider: :google,
        api_key: @provider.api_key,
        model: @provider.default_model,
        base_url: @provider.base_url
      )
    when 'mock'
      # Mock client for testing
      nil
    else
      raise "Unsupported provider type: #{@provider.provider_type}"
    end
  end

  def generate_openai_response(messages, model)
    return generate_mock_response(messages) unless @client

    response = @client.chat(
      messages: format_messages_for_openai(messages),
      model: model,
      temperature: 0.7,
      max_tokens: 1000
    )

    {
      'content' => response.content,
      'usage' => {
        'prompt_tokens' => response.usage&.prompt_tokens || 0,
        'completion_tokens' => response.usage&.completion_tokens || 0,
        'total_tokens' => response.usage&.total_tokens || 0
      }
    }
  rescue => e
    Rails.logger.error "OpenAI API error: #{e.message}"
    raise e
  end

  def generate_anthropic_response(messages, model)
    return generate_mock_response(messages) unless @client

    response = @client.chat(
      messages: format_messages_for_anthropic(messages),
      model: model,
      temperature: 0.7,
      max_tokens: 1000
    )

    {
      'content' => response.content,
      'usage' => {
        'prompt_tokens' => response.usage&.prompt_tokens || 0,
        'completion_tokens' => response.usage&.completion_tokens || 0,
        'total_tokens' => response.usage&.total_tokens || 0
      }
    }
  rescue => e
    Rails.logger.error "Anthropic API error: #{e.message}"
    raise e
  end

  def generate_google_response(messages, model)
    return generate_mock_response(messages) unless @client

    response = @client.chat(
      messages: format_messages_for_google(messages),
      model: model,
      temperature: 0.7,
      max_tokens: 1000
    )

    {
      'content' => response.content,
      'usage' => {
        'prompt_tokens' => response.usage&.prompt_tokens || 0,
        'completion_tokens' => response.usage&.completion_tokens || 0,
        'total_tokens' => response.usage&.total_tokens || 0
      }
    }
  rescue => e
    Rails.logger.error "Google API error: #{e.message}"
    raise e
  end

  def generate_openai_response_with_tools(messages, tools, model)
    return generate_mock_response_with_tools(messages, tools) unless @client

    response = @client.chat.with_tools(
      messages: format_messages_for_openai(messages),
      tools: tools,
      model: model,
      temperature: 0.7,
      max_tokens: 1000
    )

    {
      'content' => response.content,
      'tool_calls' => response.tool_calls || [],
      'usage' => {
        'prompt_tokens' => response.usage&.prompt_tokens || 0,
        'completion_tokens' => response.usage&.completion_tokens || 0,
        'total_tokens' => response.usage&.total_tokens || 0
      }
    }
  rescue => e
    Rails.logger.error "OpenAI API error with tools: #{e.message}"
    raise e
  end

  def generate_anthropic_response_with_tools(messages, tools, model)
    return generate_mock_response_with_tools(messages, tools) unless @client

    response = @client.chat.with_tools(
      messages: format_messages_for_anthropic(messages),
      tools: tools,
      model: model,
      temperature: 0.7,
      max_tokens: 1000
    )

    {
      'content' => response.content,
      'tool_calls' => response.tool_calls || [],
      'usage' => {
        'prompt_tokens' => response.usage&.prompt_tokens || 0,
        'completion_tokens' => response.usage&.completion_tokens || 0,
        'total_tokens' => response.usage&.total_tokens || 0
      }
    }
  rescue => e
    Rails.logger.error "Anthropic API error with tools: #{e.message}"
    raise e
  end

  def generate_google_response_with_tools(messages, tools, model)
    return generate_mock_response_with_tools(messages, tools) unless @client

    response = @client.chat.with_tools(
      messages: format_messages_for_google(messages),
      tools: tools,
      model: model,
      temperature: 0.7,
      max_tokens: 1000
    )

    {
      'content' => response.content,
      'tool_calls' => response.tool_calls || [],
      'usage' => {
        'prompt_tokens' => response.usage&.prompt_tokens || 0,
        'completion_tokens' => response.usage&.completion_tokens || 0,
        'total_tokens' => response.usage&.total_tokens || 0
      }
    }
  rescue => e
    Rails.logger.error "Google API error with tools: #{e.message}"
    raise e
  end

  def generate_mock_response(messages)
    last_message = messages.last
    user_content = last_message[:content] || last_message['content'] || "Hello"
    
    response_content = case @provider.provider_type
    when 'openai'
      "I'm an OpenAI-powered assistant. You said: '#{user_content}'. How can I help you further?"
    when 'anthropic'
      "I'm a Claude-powered assistant. You said: '#{user_content}'. How can I help you further?"
    when 'google'
      "I'm a Google Gemini-powered assistant. You said: '#{user_content}'. How can I help you further?"
    else
      "I'm an AI assistant. You said: '#{user_content}'. How can I help you further?"
    end

    {
      'content' => response_content,
      'usage' => {
        'prompt_tokens' => user_content.length / 4 + 50,
        'completion_tokens' => response_content.length / 4,
        'total_tokens' => (user_content.length + response_content.length) / 4 + 50
      }
    }
  end

  def generate_mock_response_with_tools(messages, tools)
    last_message = messages.last
    user_content = last_message[:content] || last_message['content'] || "Hello"
    
    response_content = case @provider.provider_type
    when 'openai'
      "I'm an OpenAI-powered assistant with #{tools.length} tools available. You said: '#{user_content}'. How can I help you further?"
    when 'anthropic'
      "I'm a Claude-powered assistant with #{tools.length} tools available. You said: '#{user_content}'. How can I help you further?"
    when 'google'
      "I'm a Google Gemini-powered assistant with #{tools.length} tools available. You said: '#{user_content}'. How can I help you further?"
    else
      "I'm an AI assistant with #{tools.length} tools available. You said: '#{user_content}'. How can I help you further?"
    end

    {
      'content' => response_content,
      'tool_calls' => [],
      'usage' => {
        'prompt_tokens' => user_content.length / 4 + 50,
        'completion_tokens' => response_content.length / 4,
        'total_tokens' => (user_content.length + response_content.length) / 4 + 50
      }
    }
  end

  def format_messages_for_openai(messages)
    messages.map do |msg|
      {
        role: msg[:role] || msg['role'],
        content: msg[:content] || msg['content']
      }
    end
  end

  def format_messages_for_anthropic(messages)
    messages.map do |msg|
      {
        role: msg[:role] || msg['role'],
        content: msg[:content] || msg['content']
      }
    end
  end

  def format_messages_for_google(messages)
    messages.map do |msg|
      {
        role: msg[:role] || msg['role'],
        content: msg[:content] || msg['content']
      }
    end
  end
end
