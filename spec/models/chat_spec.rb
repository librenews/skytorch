require 'rails_helper'

RSpec.describe Chat, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:messages).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:status) }
    # Note: enum validation is handled by Rails enum, not by shoulda-matchers
  end

  describe 'enums' do
    it 'defines status enum' do
      expect(Chat.statuses).to eq({
        'active' => 'active',
        'archived' => 'archived',
        'reported' => 'reported'
      })
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:chat)).to be_valid
    end

    it 'has a valid factory with messages' do
      chat = create(:chat, :with_messages)
      expect(chat.messages.count).to eq(3)
    end

    it 'has a valid archived factory' do
      expect(build(:chat, :archived)).to be_valid
    end

    it 'has a valid reported factory' do
      expect(build(:chat, :reported)).to be_valid
    end
  end

  describe 'scopes' do
    let!(:active_chat) { create(:chat, status: 'active') }
    let!(:archived_chat) { create(:chat, status: 'archived') }
    let!(:reported_chat) { create(:chat, status: 'reported') }

    describe '.active' do
      it 'returns only active chats' do
        expect(Chat.active).to include(active_chat)
        expect(Chat.active).not_to include(archived_chat, reported_chat)
      end
    end

    describe '.archived' do
      it 'returns only archived chats' do
        expect(Chat.archived).to include(archived_chat)
        expect(Chat.archived).not_to include(active_chat, reported_chat)
      end
    end

    describe '.reported' do
      it 'returns only reported chats' do
        expect(Chat.reported).to include(reported_chat)
        expect(Chat.reported).not_to include(active_chat, archived_chat)
      end
    end
  end

  describe 'status transitions' do
    let(:chat) { create(:chat, status: 'active') }

    it 'can transition to archived' do
      chat.update!(status: 'archived')
      expect(chat.reload.status).to eq('archived')
    end

    it 'can transition to reported' do
      chat.update!(status: 'reported')
      expect(chat.reload.status).to eq('reported')
    end

    it 'can transition back to active' do
      chat.update!(status: 'archived')
      chat.update!(status: 'active')
      expect(chat.reload.status).to eq('active')
    end
  end

  describe 'message associations' do
    let(:chat) { create(:chat) }

    it 'can have multiple messages' do
      create_list(:message, 3, chat: chat)
      expect(chat.messages.count).to eq(3)
    end

    it 'destroys messages when chat is destroyed' do
      create_list(:message, 2, chat: chat)
      expect { chat.destroy }.to change(Message, :count).by(-2)
    end
  end

  describe 'user association' do
    let(:user) { create(:user) }
    let(:chat) { create(:chat, user: user) }

    it 'belongs to a user' do
      expect(chat.user).to eq(user)
    end

    it 'is destroyed when user is destroyed' do
      chat # create the chat
      expect { user.destroy }.to change(Chat, :count).by(-1)
    end
  end

  describe 'title validation' do
    let(:user) { create(:user) }

    it 'requires a title' do
      chat = build(:chat, title: nil, user: user)
      expect(chat).not_to be_valid
      expect(chat.errors[:title]).to include("can't be blank")
    end

    it 'allows empty string title' do
      chat = build(:chat, title: '', user: user)
      expect(chat).not_to be_valid
      expect(chat.errors[:title]).to include("can't be blank")
    end
  end

  describe 'status validation' do
    let(:user) { create(:user) }

    it 'requires a status' do
      chat = build(:chat, status: nil, user: user)
      expect(chat).not_to be_valid
      expect(chat.errors[:status]).to include("can't be blank")
    end

    it 'accepts valid statuses' do
      %w[active archived reported].each do |status|
        chat = build(:chat, status: status, user: user)
        expect(chat).to be_valid
      end
    end
  end

  describe 'default values' do
    let(:user) { create(:user) }

    it 'sets default status to active' do
      chat = Chat.create!(title: 'Test Chat', user: user)
      expect(chat.status).to eq('active')
    end
  end

  describe 'ordering' do
    let(:user) { create(:user) }
    let!(:chat1) { create(:chat, title: 'First Chat', user: user, created_at: 1.day.ago) }
    let!(:chat2) { create(:chat, title: 'Second Chat', user: user, created_at: 2.days.ago) }
    let!(:chat3) { create(:chat, title: 'Third Chat', user: user, created_at: 3.days.ago) }

    it 'orders by created_at desc by default' do
      chats = user.chats
      expect(chats.to_a).to eq([chat1, chat2, chat3])
    end
  end

  describe 'message count' do
    let(:chat) { create(:chat) }

    it 'returns correct message count' do
      expect(chat.messages.count).to eq(0)
      
      create(:message, chat: chat)
      expect(chat.messages.count).to eq(1)
      
      create_list(:message, 3, chat: chat)
      expect(chat.messages.count).to eq(4)
    end
  end

  describe 'last message' do
    let(:chat) { create(:chat) }
    let!(:message1) { create(:message, chat: chat, created_at: 1.hour.ago) }
    let!(:message2) { create(:message, chat: chat, created_at: 30.minutes.ago) }
    let!(:message3) { create(:message, chat: chat, created_at: 15.minutes.ago) }

    it 'returns the most recent message' do
      expect(chat.messages.order(:created_at).last).to eq(message3)
    end
  end
end
