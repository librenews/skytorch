class McpClientRegistry
  class << self
    # Cache for MCP clients to prevent multiple server processes
    @@client_cache = {}
    
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
      # Check if we already have a cached client for this server
      cache_key = "#{server.class.name}-#{server.id}"
      
      if @@client_cache[cache_key] && @@client_cache[cache_key].alive?
        Rails.logger.info "Reusing cached MCP client for #{server.name}"
        return @@client_cache[cache_key]
      end
      
      config = server.config
      
      # For stdio transport, extract command, args, and env from config
      if server.transport_type == 'stdio'
        client = RubyLLM::MCP.client(
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
        client = RubyLLM::MCP.client(
          name: client_name,
          transport_type: server.transport_type.to_sym,
          config: config
        )
      end
      
      # Cache the client if creation was successful
      if client && client.alive?
        @@client_cache[cache_key] = client
        Rails.logger.info "Cached new MCP client for #{server.name}"
      end
      
      client
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
    
    def clear_client_cache
      @@client_cache.each do |key, client|
        begin
          client.stop if client.respond_to?(:stop)
        rescue => e
          Rails.logger.error "Error stopping cached client #{key}: #{e.message}"
        end
      end
      @@client_cache.clear
      Rails.logger.info "Cleared MCP client cache"
    end
  end
end
