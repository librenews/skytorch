require 'rails_helper'

RSpec.describe ChatService, type: :service do
  let(:user) { create(:user) }
  let(:provider) { create(:provider, provider_type: 'openai', api_key: 'test-key') }
  let(:chat) { create(:chat, user: user, title: 'Test Chat') }
  let(:service) { ChatService.new(provider) }

  before do
    # Mock the LLM response to avoid actual API calls
    allow_any_instance_of(ChatService).to receive(:generate_llm_response).and_return({
      'content' => 'Mock LLM response',
      'usage' => {
        'prompt_tokens' => 10,
        'completion_tokens' => 20,
        'total_tokens' => 30
      }
    })
  end

  describe '#initialize' do
    it 'uses the provided provider' do
      service = ChatService.new(provider)
      expect(service.instance_variable_get(:@provider)).to eq(provider)
    end

    it 'uses default provider when none provided' do
      default_provider = create(:provider, provider_type: 'openai', is_active: true)
      allow(Provider).to receive(:default_provider).and_return(default_provider)
      
      service = ChatService.new
      expect(service.instance_variable_get(:@provider)).to eq(default_provider)
    end
  end

  describe '#generate_response' do
    let(:user_message) { 'Hello, how are you?' }

    it 'creates an assistant message with the LLM response' do
      result = service.generate_response(chat, user_message)
      
      expect(result[:message]).to be_a(Message)
      expect(result[:message].role).to eq('assistant')
      expect(result[:message].content).to eq('Mock LLM response')
      expect(result[:message].chat).to eq(chat)
    end

    it 'includes usage data in the response' do
      result = service.generate_response(chat, user_message)
      
      expect(result[:usage]).to be_present
      expect(result[:usage].prompt_tokens).to eq(10)
      expect(result[:usage].completion_tokens).to eq(20)
      expect(result[:usage].total_tokens).to eq(30)
    end

    it 'includes cost calculation in the response' do
      result = service.generate_response(chat, user_message)
      
      expect(result[:cost]).to be_present
      expect(result[:cost]).to be_a(Numeric)
    end

    it 'stores usage data in the message' do
      result = service.generate_response(chat, user_message)
      message = result[:message]
      
      expect(message.prompt_tokens).to eq(10)
      expect(message.completion_tokens).to eq(20)
      expect(message.total_tokens).to eq(30)
      expect(message.usage_data).to be_present
    end

    it 'includes chat history in the LLM request' do
      # Create some previous messages
      create(:message, chat: chat, role: 'user', content: 'Previous message')
      create(:message, chat: chat, role: 'assistant', content: 'Previous response')
      
      expect(service).to receive(:generate_llm_response).with(
        array_including(
          { role: 'user', content: 'Previous message' },
          { role: 'assistant', content: 'Previous response' },
          { role: 'user', content: user_message }
        )
      )
      
      service.generate_response(chat, user_message)
    end

    context 'when LLM call fails' do
      before do
        allow_any_instance_of(ChatService).to receive(:generate_llm_response).and_raise(StandardError, 'API Error')
      end

      it 'creates a system error message' do
        result = service.generate_response(chat, user_message)
        
        expect(result[:message]).to be_a(Message)
        expect(result[:message].role).to eq('system')
        expect(result[:message].content).to include('Unable to generate a response')
        expect(result[:error]).to be true
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Error generating response/)
        service.generate_response(chat, user_message)
      end
    end
  end

  describe '#generate_title' do
    context 'when chat has no messages' do
      it 'returns "New Chat"' do
        title = service.generate_title(chat)
        expect(title).to eq('New Chat')
      end
    end

    context 'when chat has 1 message' do
      before do
        create(:message, chat: chat, role: 'user', content: 'This is a very long message that should be truncated')
      end

      it 'truncates the first message to 50 characters' do
        title = service.generate_title(chat)
        expect(title).to eq('This is a very long message that should be trunc...')
        expect(title.length).to eq(51) # Including the "..."
      end

      it 'does not truncate short messages' do
        chat.messages.destroy_all
        create(:message, chat: chat, role: 'user', content: 'Short message')
        
        title = service.generate_title(chat)
        expect(title).to eq('Short message')
      end
    end

    context 'when chat has 4 messages' do
      before do
        create(:message, chat: chat, role: 'user', content: 'Hello')
        create(:message, chat: chat, role: 'assistant', content: 'Hi there!')
        create(:message, chat: chat, role: 'user', content: 'How are you?')
        create(:message, chat: chat, role: 'assistant', content: 'I am doing well, thank you!')
      end

      it 'calls LLM to generate a title' do
        expect(service).to receive(:generate_llm_response).with(
          array_including(
            hash_including(role: 'system', content: /Generate a short, descriptive title/),
            hash_including(role: 'user', content: /Based on this conversation/)
          )
        ).and_return({ 'content' => 'Generated Title' })
        
        service.generate_title(chat)
      end

      it 'updates the chat title in the database' do
        allow(service).to receive(:generate_llm_response).and_return({ 'content' => 'New Title' })
        
        service.generate_title(chat)
        chat.reload
        
        expect(chat.title).to eq('New Title')
      end

      it 'returns the generated title' do
        allow(service).to receive(:generate_llm_response).and_return({ 'content' => 'Generated Title' })
        
        title = service.generate_title(chat)
        expect(title).to eq('Generated Title')
      end

      context 'when LLM call fails' do
        before do
          allow(service).to receive(:generate_llm_response).and_raise(StandardError, 'API Error')
        end

        it 'falls back to first message content' do
          title = service.generate_title(chat)
          expect(title).to eq('Hello')
        end

        it 'logs the error' do
          expect(Rails.logger).to receive(:error).with(/Error generating title with LLM/)
          service.generate_title(chat)
        end
      end
    end

    context 'when chat has other message counts' do
      before do
        create(:message, chat: chat, role: 'user', content: 'Hello')
      end

      it 'returns the first message content' do
        title = service.generate_title(chat)
        expect(title).to eq('Hello')
      end
    end
  end

  describe '#generate_response_with_tools' do
    let(:user_message) { 'Hello, how are you?' }
    let(:tools) { [{ name: 'test_tool', description: 'A test tool' }] }

    before do
      allow_any_instance_of(ChatService).to receive(:generate_llm_response_with_tools).and_return({
        'content' => 'Mock LLM response with tools',
        'tool_calls' => [{ name: 'test_tool', arguments: {} }],
        'usage' => {
          'prompt_tokens' => 15,
          'completion_tokens' => 25,
          'total_tokens' => 40
        }
      })
    end

    it 'creates an assistant message with the LLM response' do
      result = service.generate_response_with_tools(chat, user_message, tools)
      
      expect(result[:message]).to be_a(Message)
      expect(result[:message].role).to eq('assistant')
      expect(result[:message].content).to eq('Mock LLM response with tools')
    end

    it 'includes tool calls in the response' do
      result = service.generate_response_with_tools(chat, user_message, tools)
      
      expect(result[:tool_calls]).to be_present
      expect(result[:tool_calls]).to eq([{ name: 'test_tool', arguments: {} }])
    end

    it 'calls the LLM with tools' do
      expect(service).to receive(:generate_llm_response_with_tools).with(
        array_including({ role: 'user', content: user_message }),
        tools
      )
      
      service.generate_response_with_tools(chat, user_message, tools)
    end
  end

  describe '.create_chat_for_user' do
    it 'creates a new chat for the user' do
      chat = ChatService.create_chat_for_user(user)
      
      expect(chat).to be_a(Chat)
      expect(chat.user).to eq(user)
      expect(chat.title).to eq('New Chat')
      expect(chat.status).to eq('active')
    end

    it 'creates a chat with custom title' do
      chat = ChatService.create_chat_for_user(user, 'Custom Title')
      
      expect(chat.title).to eq('Custom Title')
    end

    it 'creates a welcome message' do
      chat = ChatService.create_chat_for_user(user)
      
      expect(chat.messages.count).to eq(1)
      expect(chat.messages.first.role).to eq('assistant')
      expect(chat.messages.first.content).to include('Hello! I\'m your AI assistant')
    end
  end

  describe '.archive_chat' do
    it 'archives the chat' do
      ChatService.archive_chat(chat)
      chat.reload
      
      expect(chat.status).to eq('archived')
    end
  end

  describe '.report_chat' do
    it 'reports the chat' do
      ChatService.report_chat(chat)
      chat.reload
      
      expect(chat.status).to eq('reported')
    end
  end

  describe '.delete_chat' do
    it 'deletes the chat' do
      ChatService.delete_chat(chat)
      
      expect { chat.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '.get_chat_usage' do
    before do
      create(:message, chat: chat, role: 'assistant', prompt_tokens: 10, completion_tokens: 20, total_tokens: 30)
      create(:message, chat: chat, role: 'assistant', prompt_tokens: 15, completion_tokens: 25, total_tokens: 40)
    end

    it 'returns usage statistics for the chat' do
      usage = ChatService.get_chat_usage(chat)
      
      expect(usage[:total_messages]).to eq(2)
      expect(usage[:total_tokens]).to eq(70)
      expect(usage[:prompt_tokens]).to eq(25)
      expect(usage[:completion_tokens]).to eq(45)
    end
  end

  describe '.get_user_usage' do
    let(:other_chat) { create(:chat, user: user) }

    before do
      create(:message, chat: chat, role: 'assistant', prompt_tokens: 10, completion_tokens: 20, total_tokens: 30)
      create(:message, chat: other_chat, role: 'assistant', prompt_tokens: 15, completion_tokens: 25, total_tokens: 40)
    end

    it 'returns usage statistics for the user' do
      usage = ChatService.get_user_usage(user)
      
      expect(usage[:total_chats]).to eq(2)
      expect(usage[:total_messages]).to eq(2)
      expect(usage[:total_tokens]).to eq(70)
      expect(usage[:prompt_tokens]).to eq(25)
      expect(usage[:completion_tokens]).to eq(45)
    end

    it 'filters by time period when provided' do
      usage = ChatService.get_user_usage(user, 1.day.ago)
      
      expect(usage[:total_messages]).to eq(2) # Assuming messages are recent
    end
  end
end
