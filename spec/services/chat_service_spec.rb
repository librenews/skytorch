require 'rails_helper'

RSpec.describe ChatService, type: :service do
  let(:user) { create(:user) }
  let(:provider) { create(:provider, provider_type: 'openai', api_key: 'test-key') }
  let(:chat) { create(:chat, user: user, title: 'Test Chat') }

  before do
    # Mock RubyLLM.chat to avoid actual API calls
    mock_chat = double(
      ask: double(
        content: 'Mock LLM response',
        input_tokens: 10,
        output_tokens: 20
      )
    )
    allow(RubyLLM).to receive(:chat).and_return(mock_chat)
  end



  describe '.generate_response' do
    let(:user_message) { 'Hello, how are you?' }

    it 'creates an assistant message with the LLM response' do
      result = ChatService.generate_response(chat, user_message)
      
      expect(result[:message]).to be_a(Message)
      expect(result[:message].role).to eq('assistant')
      expect(result[:message].content).to eq('Mock LLM response')
      expect(result[:message].chat).to eq(chat)
    end

    it 'includes success flag in the response' do
      result = ChatService.generate_response(chat, user_message)
      
      expect(result[:success]).to be true
    end

    it 'stores usage data in the message' do
      result = ChatService.generate_response(chat, user_message)
      message = result[:message]
      
      expect(message.prompt_tokens).to eq(10)
      expect(message.completion_tokens).to eq(20)
      expect(message.total_tokens).to eq(30)
      expect(message.usage_data).to be_present
    end

    it 'calls RubyLLM.chat.ask with the user message' do
      mock_response = double(content: 'test', input_tokens: 10, output_tokens: 20)
      expect(RubyLLM).to receive(:chat).and_return(double(ask: mock_response))
      ChatService.generate_response(chat, user_message)
    end

    context 'when LLM call fails' do
      before do
        allow(RubyLLM).to receive(:chat).and_raise(StandardError, 'API Error')
      end

      it 'creates a system error message' do
        result = ChatService.generate_response(chat, user_message)
        
        expect(result[:message]).to be_a(Message)
        expect(result[:message].role).to eq('system')
        expect(result[:message].content).to include('Unable to generate a response')
        expect(result[:error]).to be true
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Error generating response/)
        ChatService.generate_response(chat, user_message)
      end
    end
  end

  describe '.generate_title' do
    context 'when chat has no messages' do
      it 'returns "New Chat"' do
        title = ChatService.generate_title(chat)
        expect(title).to eq('New Chat')
      end
    end

    context 'when chat has 1 message' do
      before do
        create(:message, chat: chat, role: 'user', content: 'This is a very long message that should be truncated')
      end

      it 'truncates the first message to 50 characters' do
        title = ChatService.generate_title(chat)
        expect(title).to eq('This is a very long message that should be trunc...')
        expect(title.length).to eq(51) # Including the "..."
      end

      it 'does not truncate short messages' do
        chat.messages.destroy_all
        create(:message, chat: chat, role: 'user', content: 'Short message')
        
        title = ChatService.generate_title(chat)
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
        expect(RubyLLM).to receive(:chat).and_return(
          double(ask: double(content: 'Generated Title'))
        )
        
        ChatService.generate_title(chat)
      end

      it 'updates the chat title in the database' do
        allow(RubyLLM).to receive(:chat).and_return(
          double(ask: double(content: 'New Title'))
        )
        
        ChatService.generate_title(chat)
        chat.reload
        
        expect(chat.title).to eq('New Title')
      end

      it 'returns the generated title' do
        allow(RubyLLM).to receive(:chat).and_return(
          double(ask: double(content: 'Generated Title'))
        )
        
        title = ChatService.generate_title(chat)
        expect(title).to eq('Generated Title')
      end

      context 'when LLM call fails' do
        before do
          allow(RubyLLM).to receive(:chat).and_raise(StandardError, 'API Error')
        end

        it 'falls back to first message content' do
          title = ChatService.generate_title(chat)
          expect(title).to eq('Hello')
        end

        it 'logs the error' do
          expect(Rails.logger).to receive(:error).with(/Error generating title with LLM/)
          ChatService.generate_title(chat)
        end
      end
    end

    context 'when chat has other message counts' do
      before do
        create(:message, chat: chat, role: 'user', content: 'Hello')
      end

      it 'returns the first message content' do
        title = ChatService.generate_title(chat)
        expect(title).to eq('Hello')
      end
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
