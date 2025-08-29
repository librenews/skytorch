require 'rails_helper'

RSpec.describe ConversationManager, type: :service do
  let(:user) { create(:user) }
  let(:chat) { create(:chat, user: user) }
  let(:conversation_manager) { ConversationManager.new(chat) }

  describe '#process_message' do
    context 'when no MCP clients are available' do
      before do
        allow(McpClientRegistry).to receive(:get_clients_for_chat).and_return([])
      end

      it 'generates a normal response' do
        allow(ChatService).to receive(:generate_simple_response).and_return(
          { success: true, message: double(content: 'Normal response') }
        )

        result = conversation_manager.process_message('Hello!')
        
        expect(result[:type]).to eq(:final_response)
        expect(result[:content]).to eq('Normal response')
      end
    end

    context 'when MCP clients are available' do
      let(:mock_client) { double('mcp_client') }
      let(:mock_tool) { double('tool', name: 'weather', description: 'Get weather information') }
      let(:mock_orchestrator) { double('tool_orchestrator') }

      before do
        allow(McpClientRegistry).to receive(:get_clients_for_chat).and_return([mock_client])
        allow(ToolOrchestrator).to receive(:new).and_return(mock_orchestrator)
      end

      it 'detects tools and generates clarification when parameters are missing' do
        allow(mock_orchestrator).to receive(:detect_required_tools).and_return([mock_tool])
        allow(mock_orchestrator).to receive(:check_missing_parameters).and_return([
          { tool: 'weather', parameter: 'location', description: 'City name' }
        ])
        allow(mock_orchestrator).to receive(:generate_clarification_question).and_return('Which city?')

        result = conversation_manager.process_message('What should I wear today?')
        
        expect(result[:type]).to eq(:clarification)
        expect(result[:content]).to eq('Which city?')
      end

      it 'executes tools when all parameters are available' do
        allow(mock_orchestrator).to receive(:detect_required_tools).and_return([mock_tool])
        allow(mock_orchestrator).to receive(:check_missing_parameters).and_return([])
        allow(mock_orchestrator).to receive(:execute_tool_chain).and_return([
          { tool: 'weather', content: '72°F, Sunny' }
        ])
        allow(mock_orchestrator).to receive(:generate_response_with_partial_results).and_return('Wear light clothes')

        result = conversation_manager.process_message('What should I wear today?')
        
        expect(result[:type]).to eq(:final_response)
        expect(result[:content]).to eq('Wear light clothes')
      end
    end
  end
end
