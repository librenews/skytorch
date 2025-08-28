require 'rails_helper'

RSpec.describe McpService, type: :service do
  describe '.list_available_tools' do
    context 'when client is nil' do
      it 'returns empty array' do
        expect(McpService.list_available_tools(nil)).to eq([])
      end
    end

    context 'when client has tools' do
      let(:mock_client) { double('mcp_client') }
      let(:mock_tool) { double('tool', name: 'test_tool', description: 'Test tool', parameters: {}) }

      before do
        allow(mock_client).to receive(:tools).and_return([mock_tool])
      end

      it 'returns formatted tool information' do
        result = McpService.list_available_tools(mock_client)
        
        expect(result).to eq([
          {
            name: 'test_tool',
            description: 'Test tool',
            parameters: {}
          }
        ])
      end
    end
  end

  describe '.list_available_resources' do
    context 'when client is nil' do
      it 'returns empty array' do
        expect(McpService.list_available_resources(nil)).to eq([])
      end
    end

    context 'when client has resources' do
      let(:mock_client) { double('mcp_client') }
      let(:mock_resource) { double('resource', name: 'test_resource', description: 'Test resource', mime_type: 'text/plain') }

      before do
        allow(mock_client).to receive(:resources).and_return([mock_resource])
      end

      it 'returns formatted resource information' do
        result = McpService.list_available_resources(mock_client)
        
        expect(result).to eq([
          {
            name: 'test_resource',
            description: 'Test resource',
            mime_type: 'text/plain'
          }
        ])
      end
    end
  end

  describe '.list_available_prompts' do
    context 'when client is nil' do
      it 'returns empty array' do
        expect(McpService.list_available_prompts(nil)).to eq([])
      end
    end

    context 'when client has prompts' do
      let(:mock_client) { double('mcp_client') }
      let(:mock_argument) { double('argument', name: 'name', description: 'User name', required: true) }
      let(:mock_prompt) { double('prompt', name: 'greeting', description: 'Greeting prompt', arguments: [mock_argument]) }

      before do
        allow(mock_client).to receive(:prompts).and_return([mock_prompt])
      end

      it 'returns formatted prompt information' do
        result = McpService.list_available_prompts(mock_client)
        
        expect(result).to eq([
          {
            name: 'greeting',
            description: 'Greeting prompt',
            arguments: [
              {
                name: 'name',
                description: 'User name',
                required: true
              }
            ]
          }
        ])
      end
    end
  end
end
