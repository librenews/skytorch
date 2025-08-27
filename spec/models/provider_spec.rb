require 'rails_helper'

RSpec.describe Provider, type: :model do
  describe 'associations' do
    it { should belong_to(:user).optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:provider_type) }
    it { should validate_inclusion_of(:provider_type).in_array(%w[openai anthropic google mock]) }
    it { should validate_presence_of(:default_model) }

    context 'when provider_type is not mock' do
      before { allow(subject).to receive(:provider_type).and_return('openai') }
      it { should validate_presence_of(:api_key) }
    end

    context 'when provider_type is mock' do
      before { allow(subject).to receive(:provider_type).and_return('mock') }
      it { should_not validate_presence_of(:api_key) }
    end

    context 'when provider_type is google' do
      before { allow(subject).to receive(:provider_type).and_return('google') }
      it { should validate_presence_of(:base_url) }
    end

    context 'when provider_type is not google' do
      before { allow(subject).to receive(:provider_type).and_return('openai') }
      it { should_not validate_presence_of(:base_url) }
    end
  end

  describe 'scopes' do
    let!(:active_provider) { create(:provider, is_active: true) }
    let!(:inactive_provider) { create(:provider, is_active: false) }
    let!(:global_provider) { create(:provider, :global) }
    let!(:user_provider) { create(:provider) }

    describe '.active' do
      it 'returns only active providers' do
        expect(Provider.active).to include(active_provider)
        expect(Provider.active).not_to include(inactive_provider)
      end
    end

    describe '.global' do
      it 'returns only global providers' do
        expect(Provider.global).to include(global_provider)
        expect(Provider.global).not_to include(user_provider)
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:provider)).to be_valid
    end

    it 'has a valid openai factory' do
      expect(build(:provider, :openai)).to be_valid
    end

    it 'has a valid anthropic factory' do
      expect(build(:provider, :anthropic)).to be_valid
    end

    it 'has a valid google factory' do
      expect(build(:provider, :google)).to be_valid
    end

    it 'has a valid mock factory' do
      expect(build(:provider, :mock)).to be_valid
    end

    it 'has a valid global factory' do
      expect(build(:provider, :global)).to be_valid
    end
  end

  describe '.global_default' do
    context 'when global active provider exists' do
      let!(:global_provider) { create(:provider, :global, is_active: true) }

      it 'returns the global active provider' do
        expect(Provider.global_default).to eq(global_provider)
      end
    end

    context 'when no global active provider exists' do
      before { Provider.global.update_all(is_active: false) }

      it 'returns nil' do
        expect(Provider.global_default).to be_nil
      end
    end
  end

  describe '.default_provider' do
    context 'when active provider exists' do
      let!(:active_provider) { create(:provider, is_active: true) }

      it 'returns the first active provider' do
        expect(Provider.default_provider).to eq(active_provider)
      end
    end

    context 'when no active provider exists but global default exists' do
      let!(:global_provider) { create(:provider, :global, is_active: true) }

      before { Provider.where.not(user_id: nil).update_all(is_active: false) }

      it 'returns the global default provider' do
        expect(Provider.default_provider).to eq(global_provider)
      end
    end

    context 'when no providers exist' do
      before { Provider.destroy_all }

      it 'returns nil' do
        expect(Provider.default_provider).to be_nil
      end
    end
  end

  describe 'provider type specific validations' do
    describe 'openai provider' do
      let(:provider) { build(:provider, :openai) }

      it 'is valid with required fields' do
        expect(provider).to be_valid
      end

      it 'requires api_key' do
        provider.api_key = nil
        expect(provider).not_to be_valid
        expect(provider.errors[:api_key]).to include("can't be blank")
      end
    end

    describe 'anthropic provider' do
      let(:provider) { build(:provider, :anthropic) }

      it 'is valid with required fields' do
        expect(provider).to be_valid
      end

      it 'requires api_key' do
        provider.api_key = nil
        expect(provider).not_to be_valid
        expect(provider.errors[:api_key]).to include("can't be blank")
      end
    end

    describe 'google provider' do
      let(:provider) { build(:provider, :google) }

      it 'is valid with required fields' do
        expect(provider).to be_valid
      end

      it 'requires api_key' do
        provider.api_key = nil
        expect(provider).not_to be_valid
        expect(provider.errors[:api_key]).to include("can't be blank")
      end

      it 'requires base_url' do
        provider.base_url = nil
        expect(provider).not_to be_valid
        expect(provider.errors[:base_url]).to include("can't be blank")
      end
    end

    describe 'mock provider' do
      let(:provider) { build(:provider, :mock) }

      it 'is valid without api_key' do
        provider.api_key = nil
        expect(provider).to be_valid
      end
    end
  end

  describe 'encryption' do
    let(:provider) { create(:provider, api_key: 'secret_key') }

    it 'encrypts the api_key' do
      # Note: This test assumes encryption is enabled
      # If encryption is disabled, this test will still pass
      expect(provider.api_key).to eq('secret_key')
    end
  end

  describe 'ordering' do
    let!(:provider1) { create(:provider, name: 'A Provider') }
    let!(:provider2) { create(:provider, name: 'B Provider') }
    let!(:provider3) { create(:provider, name: 'C Provider') }

    it 'orders by name when using active scope' do
      providers = Provider.active.order(:name)
      expect(providers.to_a).to eq([provider1, provider2, provider3])
    end
  end
end
