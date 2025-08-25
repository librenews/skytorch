class AtProtocolService
  def initialize
    # Create a temporary config hash for minisky
    config = {
      'id' => Rails.application.credentials.bluesky_handle,
      'pass' => Rails.application.credentials.bluesky_app_password
    }
    
    # Create a temporary config file for minisky
    config_file = Tempfile.new(['minisky_config', '.yml'])
    config_file.write(config.to_yaml)
    config_file.close
    
    @client = Minisky.new('bsky.social', config_file.path)
    
    # Clean up the temporary file when the object is garbage collected
    ObjectSpace.define_finalizer(self, proc { File.delete(config_file.path) if File.exist?(config_file.path) })
  end

  # Get profile information for a user
  def get_profile(actor)
    begin
      response = @client.get_request('app.bsky.actor.getProfile', { actor: actor })
      {
        handle: response['handle'],
        display_name: response['displayName'],
        avatar_url: response['avatar'],
        description: response['description'],
        did: response['did'],
        followers_count: response['followersCount'],
        following_count: response['followsCount'],
        posts_count: response['postsCount'],
        indexed_at: response['indexedAt'],
        viewer: response['viewer'] # Contains follow/following status
      }
    rescue => e
      Rails.logger.warn "Failed to fetch profile for #{actor}: #{e.message}"
      nil
    end
  end

  # Create a session for a user
  def create_session(identifier, password)
    begin
      response = @client.post_request('com.atproto.server.createSession', {
        identifier: identifier,
        password: password
      })
      {
        access_jwt: response['accessJwt'],
        refresh_jwt: response['refreshJwt'],
        handle: response['handle'],
        did: response['did']
      }
    rescue => e
      Rails.logger.warn "Failed to create session for #{identifier}: #{e.message}"
      nil
    end
  end

  # Post a message to Bluesky
  def create_post(text, reply_to: nil, quote: nil)
    begin
      post_data = {
        text: text,
        createdAt: Time.current.iso8601,
        langs: ['en']
      }

      if reply_to
        post_data[:reply] = {
          root: reply_to[:root],
          parent: reply_to[:parent]
        }
      end

      if quote
        post_data[:embed] = {
          '$type' => 'app.bsky.embed.record',
          record: {
            uri: quote[:uri],
            cid: quote[:cid]
          }
        }
      end

      response = @client.post_request('com.atproto.repo.createRecord', {
        repo: @client.user.did,
        collection: 'app.bsky.feed.post',
        record: post_data
      })
      
      {
        uri: response['uri'],
        cid: response['cid']
      }
    rescue => e
      Rails.logger.warn "Failed to create post: #{e.message}"
      nil
    end
  end

  # Get timeline posts
  def get_timeline(limit: 20, cursor: nil)
    begin
      params = { limit: limit }
      params[:cursor] = cursor if cursor

      response = @client.get_request('app.bsky.feed.getTimeline', params)
      {
        posts: response['feed'],
        cursor: response['cursor']
      }
    rescue => e
      Rails.logger.warn "Failed to get timeline: #{e.message}"
      nil
    end
  end

  # Search for users
  def search_users(query, limit: 20)
    begin
      response = @client.get_request('app.bsky.actor.searchActors', {
        term: query,
        limit: limit
      })
      
      response['actors'].map do |actor|
        {
          did: actor['did'],
          handle: actor['handle'],
          display_name: actor['displayName'],
          avatar_url: actor['avatar'],
          description: actor['description']
        }
      end
    rescue => e
      Rails.logger.warn "Failed to search users: #{e.message}"
      []
    end
  end

  # Get user's posts
  def get_user_posts(actor, limit: 20, cursor: nil)
    begin
      params = { actor: actor, limit: limit }
      params[:cursor] = cursor if cursor

      response = @client.get_request('app.bsky.feed.getAuthorFeed', params)
      {
        posts: response['feed'],
        cursor: response['cursor']
      }
    rescue => e
      Rails.logger.warn "Failed to get posts for #{actor}: #{e.message}"
      nil
    end
  end

  # Like a post
  def like_post(uri, cid)
    begin
      response = @client.post_request('com.atproto.repo.createRecord', {
        repo: @client.user.did,
        collection: 'app.bsky.feed.like',
        record: {
          subject: { uri: uri, cid: cid },
          createdAt: Time.current.iso8601
        }
      })
      
      {
        uri: response['uri'],
        cid: response['cid']
      }
    rescue => e
      Rails.logger.warn "Failed to like post: #{e.message}"
      nil
    end
  end

  # Unlike a post
  def unlike_post(uri)
    begin
      @client.post_request('com.atproto.repo.deleteRecord', {
        repo: @client.user.did,
        collection: 'app.bsky.feed.like',
        rkey: uri.split('/').last
      })
      true
    rescue => e
      Rails.logger.warn "Failed to unlike post: #{e.message}"
      false
    end
  end

  # Repost a post
  def repost(uri, cid)
    begin
      response = @client.post_request('com.atproto.repo.createRecord', {
        repo: @client.user.did,
        collection: 'app.bsky.feed.repost',
        record: {
          subject: { uri: uri, cid: cid },
          createdAt: Time.current.iso8601
        }
      })
      
      {
        uri: response['uri'],
        cid: response['cid']
      }
    rescue => e
      Rails.logger.warn "Failed to repost: #{e.message}"
      nil
    end
  end

  # Delete a repost
  def delete_repost(uri)
    begin
      @client.post_request('com.atproto.repo.deleteRecord', {
        repo: @client.user.did,
        collection: 'app.bsky.feed.repost',
        rkey: uri.split('/').last
      })
      true
    rescue => e
      Rails.logger.warn "Failed to delete repost: #{e.message}"
      false
    end
  end

  # Follow a user
  def follow_user(did)
    begin
      response = @client.post_request('com.atproto.repo.createRecord', {
        repo: @client.user.did,
        collection: 'app.bsky.graph.follow',
        record: {
          subject: did,
          createdAt: Time.current.iso8601
        }
      })
      
      {
        uri: response['uri'],
        cid: response['cid']
      }
    rescue => e
      Rails.logger.warn "Failed to follow user: #{e.message}"
      nil
    end
  end

  # Unfollow a user
  def unfollow_user(uri)
    begin
      @client.post_request('com.atproto.repo.deleteRecord', {
        repo: @client.user.did,
        collection: 'app.bsky.graph.follow',
        rkey: uri.split('/').last
      })
      true
    rescue => e
      Rails.logger.warn "Failed to unfollow user: #{e.message}"
      false
    end
  end

  # Get user's followers
  def get_followers(actor, limit: 20, cursor: nil)
    begin
      params = { actor: actor, limit: limit }
      params[:cursor] = cursor if cursor

      response = @client.get_request('app.bsky.graph.getFollowers', params)
      {
        followers: response['followers'],
        cursor: response['cursor']
      }
    rescue => e
      Rails.logger.warn "Failed to get followers for #{actor}: #{e.message}"
      nil
    end
  end

  # Get user's following
  def get_following(actor, limit: 20, cursor: nil)
    begin
      params = { actor: actor, limit: limit }
      params[:cursor] = cursor if cursor

      response = @client.get_request('app.bsky.graph.getFollows', params)
      {
        following: response['follows'],
        cursor: response['cursor']
      }
    rescue => e
      Rails.logger.warn "Failed to get following for #{actor}: #{e.message}"
      nil
    end
  end
end
