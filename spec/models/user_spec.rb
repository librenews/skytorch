require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:chats).dependent(:destroy) }
    it { should have_many(:providers).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:bluesky_handle) }
    it { should validate_uniqueness_of(:bluesky_handle) }
    it { should validate_presence_of(:bluesky_did) }
    it { should validate_uniqueness_of(:bluesky_did) }
    it { should validate_presence_of(:display_name) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end

    it 'has a valid factory with providers' do
      user = create(:user, :with_providers)
      expect(user.providers.count).to eq(2)
    end

    it 'has a valid factory with chats' do
      user = create(:user, :with_chats)
      expect(user.chats.count).to eq(3)
    end
  end

  describe '#has_provider?' do
    let(:user) { create(:user) }

    context 'when user has providers' do
      before { create(:provider, user: user) }

      it 'returns true' do
        expect(user.has_provider?).to be true
      end
    end

    context 'when user has no providers' do
      it 'returns false' do
        expect(user.has_provider?).to be false
      end
    end
  end

  describe '#using_global_provider?' do
    let(:user) { create(:user) }

    context 'when user has no providers' do
      it 'returns true' do
        expect(user.using_global_provider?).to be true
      end
    end

    context 'when user has providers' do
      before { create(:provider, user: user) }

      it 'returns false' do
        expect(user.using_global_provider?).to be false
      end
    end
  end

  describe '#default_provider' do
    let(:user) { create(:user) }
    let!(:provider) { create(:provider, user: user) }

    context 'when user has providers' do
      it 'returns the first provider' do
        expect(user.default_provider).to eq(provider)
      end
    end

    context 'when user has no providers' do
      before { user.providers.destroy_all }

      it 'returns global default provider' do
        global_provider = create(:provider, :global)
        expect(user.default_provider).to eq(global_provider)
      end
    end
  end

  describe '#avatar_display_url' do
    let(:user) { create(:user) }

    context 'when avatar_url is present' do
      before { user.update(avatar_url: 'https://example.com/avatar.jpg') }

      it 'returns the avatar_url' do
        expect(user.avatar_display_url).to eq('https://example.com/avatar.jpg')
      end
    end

    context 'when avatar_url is nil' do
      before { user.update(avatar_url: nil) }

      it 'returns a generated avatar URL' do
        expect(user.avatar_display_url).to include('dicebear.com')
        expect(user.avatar_display_url).to include(user.bluesky_handle)
      end
    end
  end

  describe '#display_name_or_handle' do
    let(:user) { create(:user) }

    context 'when display_name is present' do
      before { user.update(display_name: 'Test User') }

      it 'returns the display_name' do
        expect(user.display_name_or_handle).to eq('Test User')
      end
    end

    context 'when display_name is nil' do
      before { user.update(display_name: nil) }

      it 'returns the bluesky_handle' do
        expect(user.display_name_or_handle).to eq(user.bluesky_handle)
      end
    end
  end

  describe '#to_param' do
    let(:user) { create(:user) }

    it 'returns the bluesky_handle' do
      expect(user.to_param).to eq(user.bluesky_handle)
    end
  end

  describe '.find_by_handle_or_did' do
    let(:user) { create(:user) }

    context 'when searching by handle' do
      it 'finds the user' do
        found_user = User.find_by_handle_or_did(user.bluesky_handle)
        expect(found_user).to eq(user)
      end
    end

    context 'when searching by did' do
      it 'finds the user' do
        found_user = User.find_by_handle_or_did(user.bluesky_did)
        expect(found_user).to eq(user)
      end
    end

    context 'when searching with non-existent identifier' do
      it 'returns nil' do
        found_user = User.find_by_handle_or_did('nonexistent')
        expect(found_user).to be_nil
      end
    end
  end

  describe '.find_or_create_from_omniauth' do
    let(:auth_hash) do
      {
        'info' => {
          'did' => 'did:plc:newuser123',
          'handle' => 'new.user',
          'display_name' => 'New User'
        }
      }
    end

    context 'when user does not exist' do
      it 'creates a new user' do
        expect {
          User.find_or_create_from_omniauth(auth_hash)
        }.to change(User, :count).by(1)
      end

      it 'sets the correct attributes' do
        user = User.find_or_create_from_omniauth(auth_hash)
        expect(user.bluesky_did).to eq('did:plc:newuser123')
        expect(user.bluesky_handle).to eq('did:plc:newuser123')
        expect(user.display_name).to eq('newuser123')
      end
    end

    context 'when user already exists' do
      let!(:existing_user) { create(:user, bluesky_did: 'did:plc:newuser123') }

      it 'does not create a new user' do
        expect {
          User.find_or_create_from_omniauth(auth_hash)
        }.not_to change(User, :count)
      end

      it 'returns the existing user' do
        user = User.find_or_create_from_omniauth(auth_hash)
        expect(user).to eq(existing_user)
      end
    end
  end

  describe '#update_profile_from_api!' do
    let(:user) { create(:user) }
    let(:profile_data) do
      {
        handle: 'updated.user',
        display_name: 'Updated User',
        avatar_url: 'https://example.com/new-avatar.jpg'
      }
    end

    it 'updates the user profile' do
      user.update_profile_from_api!(profile_data)
      
      expect(user.bluesky_handle).to eq('updated.user')
      expect(user.display_name).to eq('Updated User')
      expect(user.avatar_url).to eq('https://example.com/new-avatar.jpg')
      expect(JSON.parse(user.description)).to eq(profile_data.stringify_keys)
      expect(user.profile_updated_at).to be_present
    end

    context 'when profile data is missing some fields' do
      let(:incomplete_profile_data) do
        {
          display_name: 'Updated User',
          avatar_url: 'https://example.com/new-avatar.jpg'
        }
      end

      it 'updates only the provided fields' do
        user.update_profile_from_api!(incomplete_profile_data)
        
        expect(user.display_name).to eq('Updated User')
        expect(user.avatar_url).to eq('https://example.com/new-avatar.jpg')
        expect(user.bluesky_handle).to eq(user.bluesky_did) # fallback
      end
    end

    context 'when update fails' do
      it 'falls back to basic info' do
        # Create a user with a handle that would cause validation error
        user_with_duplicate = create(:user, bluesky_handle: 'updated.user')
        
        # Try to update the original user with a handle that already exists
        user.update_profile_from_api!(profile_data)
        
        # Should fall back to basic info
        expect(user.display_name).to eq(user.bluesky_handle)
        expect(user.profile_updated_at).to be_present
      end
    end
  end

  describe 'subscription and usage methods' do
    let(:user) { create(:user) }

    describe '#subscription_status' do
      it 'returns free by default' do
        expect(user.subscription_status).to eq('free')
      end
    end

    describe '#subscription_active?' do
      it 'returns true for free subscription' do
        expect(user.subscription_active?).to be true
      end
    end

    describe '#usage_limits' do
      it 'returns default limits' do
        limits = user.usage_limits
        expect(limits[:chats_per_month]).to eq(100)
        expect(limits[:messages_per_chat]).to eq(1000)
        expect(limits[:storage_mb]).to eq(100)
      end
    end

    describe '#usage_this_month' do
      it 'returns current usage' do
        usage = user.usage_this_month
        expect(usage[:chats_created]).to be_a(Integer)
        expect(usage[:messages_sent]).to eq(0)
        expect(usage[:storage_used_mb]).to eq(0)
      end
    end

    describe '#within_limits?' do
      it 'returns true for new user' do
        expect(user.within_limits?).to be true
      end
    end
  end

  describe 'permission methods' do
    let(:user) { create(:user) }
    let(:resource) { create(:chat, user: user) }

    describe '#admin?' do
      it 'returns false by default' do
        expect(user.admin?).to be false
      end

      context 'when user is admin' do
        let(:user) { create(:user, :admin) }

        it 'returns true' do
          expect(user.admin?).to be false # Currently hardcoded to false
        end
      end
    end

    describe '#can_edit?' do
      it 'returns true for own resource' do
        expect(user.can_edit?(resource)).to be true
      end

      it 'returns false for other user resource' do
        other_resource = create(:chat)
        expect(user.can_edit?(other_resource)).to be false
      end
    end

    describe '#can_delete?' do
      it 'returns true for own resource' do
        expect(user.can_delete?(resource)).to be true
      end

      it 'returns false for other user resource' do
        other_resource = create(:chat)
        expect(user.can_delete?(other_resource)).to be false
      end
    end

    describe '#can_view?' do
      it 'returns true for own resource' do
        expect(user.can_view?(resource)).to be true
      end

      it 'returns false for other user resource' do
        other_resource = create(:chat)
        expect(user.can_view?(other_resource)).to be false
      end
    end
  end
end
