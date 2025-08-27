require 'rails_helper'

RSpec.describe Message, type: :model do
  describe 'associations' do
    it { should belong_to(:chat) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:role) }
    it { should validate_inclusion_of(:role).in_array(%w[user assistant system]) }
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
  end

  describe 'role validation' do
    let(:chat) { create(:chat) }

    it 'accepts valid roles' do
      %w[user assistant system].each do |role|
        message = build(:message, role: role, chat: chat)
        expect(message).to be_valid
      end
    end

    it 'rejects invalid roles' do
      message = build(:message, role: 'invalid_role', chat: chat)
      expect(message).not_to be_valid
      expect(message.errors[:role]).to include('is not included in the list')
    end

    it 'requires a role' do
      message = build(:message, role: nil, chat: chat)
      expect(message).not_to be_valid
      expect(message.errors[:role]).to include("can't be blank")
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
