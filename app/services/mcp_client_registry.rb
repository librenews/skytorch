class McpClientRegistry
  class << self
    def get_clients_for_chat(chat)
      clients = []
      
      # Add global clients
      clients.concat(get_global_clients)
      
      # Add user-specific clients
      clients.concat(get_user_clients(chat.user))
      
      # Add chat-specific clients
      clients.concat(get_chat_clients(chat))
      
      clients
    end

    def get_global_clients
      GlobalMcpServer.active.map do |server|
        create_client_from_server(server, "global-#{server.name}")
      end
    end

    def get_user_clients(user)
      UserMcpServer.where(user: user, is_active: true).map do |server|
        create_client_from_server(server, "user-#{user.id}-#{server.name}")
      end
    end

    def get_chat_clients(chat)
      ChatMcpServer.where(chat: chat, is_active: true).map do |server|
        create_client_from_server(server, "chat-#{chat.id}-#{server.name}")
      end
    end

    def create_client_from_server(server, client_name)
      config = server.config
      
      # For stdio transport, extract command, args, and env from config
      if server.transport_type == 'stdio'
        RubyLLM::MCP.client(
          name: client_name,
          transport_type: server.transport_type.to_sym,
          config: {
            command: config['command'],
            args: config['args'],
            env: config['env']
          }
        )
      else
        # For other transport types, pass config as is
        RubyLLM::MCP.client(
          name: client_name,
          transport_type: server.transport_type.to_sym,
          config: config
        )
      end
    rescue => e
      Rails.logger.error "Failed to create MCP client for #{server.name}: #{e.message}"
      nil
    end

    def seed_default_servers
      GlobalMcpServer.default_servers.each do |server_config|
        GlobalMcpServer.find_or_create_by(name: server_config[:name]) do |server|
          server.transport_type = server_config[:transport_type]
          server.config = server_config[:config]
          server.is_active = server_config[:is_active]
        end
      end
    end
  end
end
