require 'rails_helper'

RSpec.describe Message, type: :model do
  describe 'associations' do
    it { should belong_to(:chat) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }
    # Note: role validation is handled by Rails enum, not by shoulda-matchers
    
    # Usage tracking validations
    it { should validate_numericality_of(:prompt_tokens).only_integer.is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_numericality_of(:completion_tokens).only_integer.is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_numericality_of(:total_tokens).only_integer.is_greater_than_or_equal_to(0).allow_nil }
  end

  describe 'enums' do
    it 'defines role enum' do
      expect(Message.roles).to eq({
        'user' => 'user',
        'assistant' => 'assistant',
        'system' => 'system'
      })
    end
  end

  describe 'scopes' do
    let!(:user_message) { create(:message, :user) }
    let!(:assistant_message) { create(:message, :assistant) }
    let!(:system_message) { create(:message, :system) }
    let!(:message_with_usage) { create(:message, :with_usage) }

    describe '.assistant_messages' do
      it 'returns only assistant messages' do
        expect(Message.assistant_messages).to include(assistant_message, message_with_usage)
        expect(Message.assistant_messages).not_to include(user_message, system_message)
      end
    end

    describe '.with_usage' do
      it 'returns only messages with usage data' do
        expect(Message.with_usage).to include(message_with_usage)
        expect(Message.with_usage).not_to include(user_message, assistant_message, system_message)
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:message)).to be_valid
    end

    it 'has a valid user message factory' do
      expect(build(:message, :user)).to be_valid
    end

    it 'has a valid assistant message factory' do
      expect(build(:message, :assistant)).to be_valid
    end

    it 'has a valid system message factory' do
      expect(build(:message, :system)).to be_valid
    end

    it 'has a valid factory with usage data' do
      expect(build(:message, :with_usage)).to be_valid
    end

    it 'has a valid factory with OpenAI usage' do
      expect(build(:message, :openai_usage)).to be_valid
    end

    it 'has a valid factory with Anthropic usage' do
      expect(build(:message, :anthropic_usage)).to be_valid
    end

    it 'has a valid factory with Google usage' do
      expect(build(:message, :google_usage)).to be_valid
    end
  end

  describe 'role validation' do
    let(:chat) { create(:chat) }

    it 'accepts valid roles' do
      %w[user assistant system].each do |role|
        message = build(:message, role: role, chat: chat)
        expect(message).to be_valid
      end
    end
  end

  describe 'content validation' do
    let(:chat) { create(:chat) }

    it 'requires content' do
      message = build(:message, content: nil, chat: chat)
      expect(message).not_to be_valid
      expect(message.errors[:content]).to include("can't be blank")
    end

    it 'allows empty string content' do
      message = build(:message, content: '', chat: chat)
      expect(message).not_to be_valid
      expect(message.errors[:content]).to include("can't be blank")
    end

    it 'allows long content' do
      long_content = "This is a very long message with lots of content that might exceed normal limits and test how the system handles longer messages in the chat interface." * 10
      message = build(:message, content: long_content, chat: chat)
      expect(message).to be_valid
    end

    it 'allows special characters' do
      special_content = "Message with special chars: @#$%^&*()_+-=[]{}|;':\",./<>?"
      message = build(:message, content: special_content, chat: chat)
      expect(message).to be_valid
    end
  end

  describe 'usage tracking' do
    let(:chat) { create(:chat) }

    describe '#has_usage_data?' do
      it 'returns true when total_tokens is present' do
        message = create(:message, :with_usage, chat: chat)
        expect(message.has_usage_data?).to be true
      end

      it 'returns false when total_tokens is nil' do
        message = create(:message, :assistant, chat: chat)
        expect(message.has_usage_data?).to be false
      end
    end

    describe '#cost_estimate' do
      it 'returns 0 when no usage data' do
        message = create(:message, :assistant, chat: chat)
        expect(message.cost_estimate).to eq(0)
      end

      it 'returns estimated cost when usage data is present' do
        message = create(:message, :with_usage, chat: chat)
        expected_cost = message.total_tokens * 0.0001
        expect(message.cost_estimate).to eq(expected_cost)
      end
    end

    describe '#set_usage_data' do
      let(:message) { create(:message, :assistant, chat: chat) }
      let(:usage_hash) do
        {
          prompt_tokens: 100,
          completion_tokens: 50,
          total_tokens: 150,
          model: 'gpt-4o-mini'
        }
      end

      it 'sets usage data correctly' do
        message.set_usage_data(usage_hash)
        
        expect(message.prompt_tokens).to eq(100)
        expect(message.completion_tokens).to eq(50)
        expect(message.total_tokens).to eq(150)
        expect(message.usage_data).to eq(usage_hash.stringify_keys)
      end
    end
  end

  describe 'chat association' do
    let(:chat) { create(:chat) }
    let(:message) { create(:message, chat: chat) }

    it 'belongs to a chat' do
      expect(message.chat).to eq(chat)
    end

    it 'is destroyed when chat is destroyed' do
      message # create the message
      expect { chat.destroy }.to change(Message, :count).by(-1)
    end
  end

  describe 'role-specific behavior' do
    let(:chat) { create(:chat) }

    describe 'user messages' do
      let(:user_message) { create(:message, :user, chat: chat) }

      it 'has user role' do
        expect(user_message.role).to eq('user')
      end

      it 'has appropriate content' do
        expect(user_message.content).to eq('Hello, how can you help me?')
      end
    end

    describe 'assistant messages' do
      let(:assistant_message) { create(:message, :assistant, chat: chat) }

      it 'has assistant role' do
        expect(assistant_message.role).to eq('assistant')
      end

      it 'has appropriate content' do
        expect(assistant_message.content).to eq("I'm here to help! What would you like to know?")
      end
    end

    describe 'system messages' do
      let(:system_message) { create(:message, :system, chat: chat) }

      it 'has system role' do
        expect(system_message.role).to eq('system')
      end

      it 'has appropriate content' do
        expect(system_message.content).to eq('You are a helpful AI assistant.')
      end
    end
  end

  describe 'ordering' do
    let(:chat) { create(:chat) }
    let!(:message1) { create(:message, chat: chat, created_at: 1.hour.ago) }
    let!(:message2) { create(:message, chat: chat, created_at: 30.minutes.ago) }
    let!(:message3) { create(:message, chat: chat, created_at: 15.minutes.ago) }

    it 'orders by created_at by default' do
      messages = chat.messages
      expect(messages.to_a).to eq([message1, message2, message3])
    end

    it 'can be ordered by created_at desc' do
      messages = chat.messages.order(created_at: :desc)
      expect(messages.to_a).to eq([message3, message2, message1])
    end
  end

  describe 'content length' do
    let(:chat) { create(:chat) }

    it 'handles very long content' do
      long_content = "A" * 10000
      message = create(:message, content: long_content, chat: chat)
      expect(message).to be_valid
      expect(message.content.length).to eq(10000)
    end

    it 'handles short content' do
      short_content = "Hi"
      message = create(:message, content: short_content, chat: chat)
      expect(message).to be_valid
      expect(message.content).to eq("Hi")
    end
  end

  describe 'special characters' do
    let(:chat) { create(:chat) }

    it 'handles special characters in content' do
      special_content = "Test message with: @#$%^&*()_+-=[]{}|;':\",./<>? and emojis 🚀🎉💻"
      message = create(:message, content: special_content, chat: chat)
      expect(message).to be_valid
      expect(message.content).to eq(special_content)
    end
  end

  describe 'message sequence' do
    let(:chat) { create(:chat) }

    it 'maintains proper sequence in chat' do
      message1 = create(:message, :user, chat: chat)
      message2 = create(:message, :assistant, chat: chat)
      message3 = create(:message, :user, chat: chat)

      messages = chat.messages.order(:created_at)
      expect(messages.to_a).to eq([message1, message2, message3])
    end
  end

  describe 'timestamps' do
    let(:chat) { create(:chat) }
    let(:message) { create(:message, chat: chat) }

    it 'sets created_at timestamp' do
      expect(message.created_at).to be_present
    end

    it 'sets updated_at timestamp' do
      expect(message.updated_at).to be_present
    end

    it 'updates updated_at when content changes' do
      original_updated_at = message.updated_at
      sleep(1.second)
      message.update!(content: 'Updated content')
      expect(message.updated_at).to be > original_updated_at
    end
  end
end
