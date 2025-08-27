require 'rails_helper'

RSpec.describe Message, type: :model do
  let(:user) { create(:user) }
  let(:chat) { create(:chat, user: user) }
  let(:provider) { create(:provider, provider_type: 'openai') }

  describe 'validations' do
    it { should validate_presence_of(:content) }
    
    # Note: role validation is handled by Rails enum, not by shoulda-matchers
    
    # Usage tracking validations
    it { should validate_numericality_of(:prompt_tokens).only_integer.is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_numericality_of(:completion_tokens).only_integer.is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_numericality_of(:total_tokens).only_integer.is_greater_than_or_equal_to(0).allow_nil }
  end

  describe 'associations' do
    it { should belong_to(:chat) }
  end

  describe 'scopes' do
    let!(:assistant_message) { create(:message, chat: chat, role: 'assistant') }
    let!(:message_with_usage) { create(:message, chat: chat, role: 'assistant', total_tokens: 100) }
    let!(:message_without_usage) { create(:message, chat: chat, role: 'assistant', total_tokens: nil) }

    describe '.assistant_messages' do
      it 'returns only assistant messages' do
        expect(Message.assistant_messages).to include(assistant_message, message_with_usage, message_without_usage)
      end
    end

    describe '.with_usage' do
      it 'returns only messages with usage data' do
        expect(Message.with_usage).to include(message_with_usage)
        expect(Message.with_usage).not_to include(message_without_usage)
      end
    end
  end

  describe 'factory' do
    it 'creates a valid message' do
      message = build(:message, chat: chat)
      expect(message).to be_valid
    end

    it 'creates a user message by default' do
      message = create(:message, chat: chat)
      expect(message.role).to eq('user')
    end

    it 'allows creating different role messages' do
      assistant_message = create(:message, :assistant, chat: chat)
      system_message = create(:message, :system, chat: chat)

      expect(assistant_message.role).to eq('assistant')
      expect(system_message.role).to eq('system')
    end
  end

  describe 'usage tracking' do
    let(:message) { create(:message, chat: chat, role: 'assistant') }

    describe '#has_usage_data?' do
      it 'returns false when no usage data exists' do
        expect(message.has_usage_data?).to be false
      end

      it 'returns true when usage data exists' do
        message.update!(total_tokens: 100)
        expect(message.has_usage_data?).to be true
      end
    end

    describe '#cost_estimate' do
      it 'returns 0 when no usage data exists' do
        expect(message.cost_estimate).to eq(0)
      end

      it 'calculates cost based on tokens' do
        message.update!(
          prompt_tokens: 100,
          completion_tokens: 50,
          total_tokens: 150
        )
        
        # Expected: 150 * 0.0001 = 0.015
        expect(message.cost_estimate).to be_within(0.000001).of(0.015)
      end
    end

    describe '#set_usage_data' do
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

  describe 'role enum' do
    it 'defines role enum' do
      expect(Message.roles).to eq({
        'user' => 'user',
        'assistant' => 'assistant',
        'system' => 'system'
      })
    end
  end

  describe 'message ordering' do
    let!(:message1) { create(:message, chat: chat, created_at: 1.hour.ago) }
    let!(:message2) { create(:message, chat: chat, created_at: 30.minutes.ago) }
    let!(:message3) { create(:message, chat: chat, created_at: 15.minutes.ago) }

    it 'orders by created_at by default' do
      messages = chat.messages.to_a
      expect(messages).to eq([message1, message2, message3])
    end
  end

  describe 'message roles' do
    describe 'user messages' do
      let(:message) { create(:message, chat: chat, role: 'user') }

      it 'identifies user messages correctly' do
        expect(message.user?).to be true
        expect(message.assistant?).to be false
        expect(message.system?).to be false
      end
    end

    describe 'assistant messages' do
      let(:message) { create(:message, chat: chat, role: 'assistant') }

      it 'identifies assistant messages correctly' do
        expect(message.user?).to be false
        expect(message.assistant?).to be true
        expect(message.system?).to be false
      end
    end

    describe 'system messages' do
      let(:message) { create(:message, chat: chat, role: 'system') }

      it 'identifies system messages correctly' do
        expect(message.user?).to be false
        expect(message.assistant?).to be false
        expect(message.system?).to be true
      end
    end
  end

  describe 'usage data storage' do
    let(:message) { create(:message, chat: chat, role: 'assistant') }

    it 'stores usage data as JSON' do
      usage_data = {
        'prompt_tokens' => 100,
        'completion_tokens' => 50,
        'total_tokens' => 150,
        'model' => 'gpt-4o-mini'
      }

      message.update!(
        prompt_tokens: 100,
        completion_tokens: 50,
        total_tokens: 150,
        usage_data: usage_data
      )

      expect(message.usage_data).to eq(usage_data)
    end

    it 'handles nil usage data' do
      message.update!(usage_data: nil)
      expect(message.usage_data).to be_nil
    end
  end

  describe 'chat association' do
    let(:message) { create(:message, chat: chat) }
    
    it 'belongs to a chat' do
      expect(message.chat).to eq(chat)
    end

    it 'is destroyed when chat is destroyed' do
      message # create the message
      expect { chat.destroy }.to change(Message, :count).by(-1)
    end
  end

  describe 'message deletion' do
    let!(:message) { create(:message, chat: chat) }

    it 'deletes the message' do
      expect { message.destroy }.to change(Message, :count).by(-1)
    end

    it 'does not affect the chat' do
      expect { message.destroy }.not_to change(Chat, :count)
    end
  end
end

