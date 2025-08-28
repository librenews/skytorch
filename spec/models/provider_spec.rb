require 'rails_helper'

RSpec.describe Provider, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:provider_type) }
    it { should validate_presence_of(:api_key) }
    it { should validate_presence_of(:default_model) }
    
    it { should validate_inclusion_of(:provider_type).in_array(%w[openai anthropic google]) }
  end

  describe 'associations' do
    it { should belong_to(:user).optional }
  end

  describe 'scopes' do
    let!(:active_provider) { create(:provider, is_active: true) }
    let!(:inactive_provider) { create(:provider, is_active: false) }

    describe '.active' do
      it 'returns only active providers' do
        expect(Provider.active).to include(active_provider)
        expect(Provider.active).not_to include(inactive_provider)
      end
    end
  end

  describe '.default_provider' do
    let!(:active_provider) { create(:provider, is_active: true) }
    let!(:inactive_provider) { create(:provider, is_active: false) }

    it 'returns the first active provider' do
      expect(Provider.default_provider).to eq(active_provider)
    end

    context 'when no active providers exist' do
      before { Provider.update_all(is_active: false) }

      it 'returns nil' do
        expect(Provider.default_provider).to be_nil
      end
    end
  end

  describe 'provider type validation' do
    it 'accepts valid provider types' do
      %w[openai anthropic].each do |provider_type|
        provider = build(:provider, provider_type: provider_type)
        expect(provider).to be_valid
      end
      
      # Google provider requires base_url
      provider = build(:provider, provider_type: 'google', base_url: 'https://api.example.com')
      expect(provider).to be_valid
    end

    it 'rejects invalid provider types' do
      provider = build(:provider, provider_type: 'invalid')
      expect(provider).not_to be_valid
      expect(provider.errors[:provider_type]).to include('is not included in the list')
    end
  end

  describe 'conditional validations' do
    context 'when provider_type is openai' do
      it 'requires api_key' do
        provider = build(:provider, provider_type: 'openai', api_key: nil)
        expect(provider).not_to be_valid
        expect(provider.errors[:api_key]).to include("can't be blank")
      end
    end

    context 'when provider_type is google' do
      it 'requires base_url' do
        provider = build(:provider, provider_type: 'google', base_url: nil)
        expect(provider).not_to be_valid
        expect(provider.errors[:base_url]).to include("can't be blank")
      end
    end

    context 'when provider_type is not google' do
      it 'does not require base_url' do
        provider = build(:provider, provider_type: 'openai', base_url: nil)
        expect(provider).to be_valid
      end
    end
  end

  describe 'factory' do
    it 'creates a valid provider' do
      provider = build(:provider)
      expect(provider).to be_valid
    end

    it 'creates an active provider by default' do
      provider = create(:provider)
      expect(provider.is_active).to be true
    end

    it 'allows creating inactive providers' do
      provider = create(:provider, is_active: false)
      expect(provider.is_active).to be false
    end
  end

  describe 'factory' do
    it 'creates a valid provider' do
      provider = build(:provider)
      expect(provider).to be_valid
    end

    it 'creates an active provider by default' do
      provider = create(:provider)
      expect(provider.is_active).to be true
    end

    it 'allows creating inactive providers' do
      provider = create(:provider, is_active: false)
      expect(provider.is_active).to be false
    end
  end
end
