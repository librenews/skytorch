import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messagesContainer", "messageInput", "messageInputContainer", "chatTitle", "chatSubtitle", "sendBtn", "settingsModal"]
  
  connect() {
    console.log("Dashboard controller connected!")
    this.currentChatId = null
    this.setupEventListeners()
    this.setupAutoResize()
    this.startProviderMonitoring()
    this.setupInfiniteScroll()
  }
  
  setupEventListeners() {
    // Use event delegation for dynamically generated elements
    this.element.addEventListener('click', (e) => {
      // New chat button
      if (e.target.closest('#new-chat-btn')) {
        e.preventDefault()
        console.log("New chat button clicked")
        this.createNewChat()
      }
      
      // Start chat button
      if (e.target.closest('#start-chat-btn')) {
        e.preventDefault()
        console.log("Start chat button clicked")
        this.createNewChat()
      }
      
      // Chat item clicks
      if (e.target.closest('.chat-item')) {
        e.preventDefault()
        const chatItem = e.target.closest('.chat-item')
        const chatId = chatItem.dataset.chatId
        console.log("Chat item clicked:", chatId)
        this.loadChat(chatId)
      }
      
      // Settings button
      if (e.target.closest('#settings-btn')) {
        e.preventDefault()
        console.log("Settings button clicked")
        this.openSettings()
      }
      
      // Close settings
      if (e.target.closest('#close-settings')) {
        e.preventDefault()
        console.log("Close settings clicked")
        this.closeSettings()
      }
    })
    
    // Send button
    if (this.hasSendBtnTarget) {
      this.sendBtnTarget.addEventListener('click', () => {
        console.log("Send button clicked")
        this.sendMessage()
      })
    }
    
    // Enter key in message input
    if (this.hasMessageInputTarget) {
      this.messageInputTarget.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault()
          console.log("Enter key pressed in message input")
          this.sendMessage()
        }
      })
    }
    
    // Close modal on backdrop click
    if (this.hasSettingsModalTarget) {
      this.settingsModalTarget.addEventListener('click', (e) => {
        if (e.target === this.settingsModalTarget) {
          this.closeSettings()
        }
      })
    }
  }
  
  setupAutoResize() {
    if (this.hasMessageInputTarget) {
      const textarea = this.messageInputTarget
      const minHeight = 44 // Minimum height in pixels
      const maxHeight = 300 // Maximum height in pixels
      
      // Add custom scrollbar styles
      textarea.style.resize = 'none'
      textarea.style.overflowY = 'hidden' // Start with hidden scrollbar
      textarea.style.scrollbarWidth = 'thin'
      textarea.style.scrollbarColor = '#cbd5e1 #f1f5f9'
      
      // Add CSS for webkit scrollbar styling
      const style = document.createElement('style')
      style.textContent = `
        textarea::-webkit-scrollbar {
          width: 6px;
        }
        textarea::-webkit-scrollbar-track {
          background: #f1f5f9;
          border-radius: 3px;
        }
        textarea::-webkit-scrollbar-thumb {
          background: #cbd5e1;
          border-radius: 3px;
        }
        textarea::-webkit-scrollbar-thumb:hover {
          background: #94a3b8;
        }
      `
      document.head.appendChild(style)
      
      textarea.addEventListener('input', () => {
        // Reset height to auto to get the correct scrollHeight
        textarea.style.height = 'auto'
        
        // Calculate new height - allow it to grow up to maxHeight
        const newHeight = Math.max(minHeight, Math.min(textarea.scrollHeight, maxHeight))
        
        // Only update if the height actually changed
        if (parseInt(textarea.style.height) !== newHeight) {
          textarea.style.height = newHeight + 'px'
        }
        
        // Show scrollbar only when at maximum height
        if (newHeight >= maxHeight) {
          textarea.style.overflowY = 'auto'
          // Scroll to bottom to show the latest content
          textarea.scrollTop = textarea.scrollHeight
        } else {
          textarea.style.overflowY = 'hidden'
        }
      })
      
      // Set initial height
      textarea.style.height = minHeight + 'px'
    }
  }
  
  async createNewChat() {
    console.log("Creating new chat...")
    try {
                const response = await fetch('/chats', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
            },
            body: JSON.stringify({
              chat: {
                title: 'New Chat'
              }
            })
          })
      
      if (response.ok) {
        const chat = await response.json()
        console.log("New chat created:", chat)
        await this.loadChat(chat.id)
        await this.updateChatList()
        // Reset infinite scroll since we have a new chat at the top
        this.resetInfiniteScroll()
      }
    } catch (error) {
      console.error('Error creating chat:', error)
    }
  }
  
  async loadChat(chatId) {
    console.log("Loading chat:", chatId)
    try {
      const response = await fetch(`/chats/${chatId}`, {
        headers: {
          'Accept': 'application/json'
        }
      })
      if (response.ok) {
        const chat = await response.json()
        this.currentChatId = chatId
        this.displayChat(chat)
        this.showMessageInput()
        
        // Highlight selected chat in sidebar
        document.querySelectorAll('.chat-item').forEach(item => {
          item.classList.remove('active')
        })
        const selectedItem = document.querySelector(`[data-chat-id="${chatId}"]`)
        if (selectedItem) {
          selectedItem.classList.add('active')
        }
      }
    } catch (error) {
      console.error('Error loading chat:', error)
    }
  }
  
  displayChat(chat) {
    console.log("Displaying chat:", chat)
    this.chatTitleTarget.textContent = chat.title
    this.chatSubtitleTarget.textContent = `${chat.messages.length} messages`
    
    // Clear and populate messages
    this.messagesContainerTarget.innerHTML = ''
    
    if (chat.messages.length === 0) {
      this.showWelcomeMessage()
    } else {
      chat.messages.forEach(message => {
        this.addMessage(message)
      })
    }
    
    this.scrollToBottom()
  }
  
  showWelcomeMessage() {
    this.messagesContainerTarget.innerHTML = `
      <div class="text-center py-12">
        <div class="w-16 h-16 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center mx-auto mb-4">
          <span class="text-3xl">🚀</span>
        </div>
        <h3 class="text-lg font-medium text-gray-900 mb-2">New Chat Started</h3>
        <p class="text-gray-500">Start typing to begin your conversation with AI</p>
      </div>
    `
  }
  
  addMessage(message) {
    const messageElement = document.createElement('div')
    messageElement.className = 'flex space-x-4 mb-4'
    
    const isUser = message.role === 'user'
    const alignment = isUser ? 'justify-end' : 'justify-start'
    const bgColor = isUser ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-900'
    
    messageElement.innerHTML = `
      <div class="flex ${alignment} w-full">
        <div class="max-w-3xl ${bgColor} rounded-lg px-4 py-3">
          <div class="whitespace-pre-wrap">${message.content}</div>
        </div>
      </div>
    `
    
    this.messagesContainerTarget.appendChild(messageElement)
  }
  
  async sendMessage() {
    const content = this.messageInputTarget.value.trim()
    if (!content || !this.currentChatId) return
    
    console.log("Sending message:", content)
    
    // Add user message immediately
    const userMessage = {
      role: 'user',
      content: content
    }
    this.addMessage(userMessage)
    
    // Clear input and reset height
    this.messageInputTarget.value = ''
    this.messageInputTarget.style.height = '44px' // Reset to minimum height
    this.messageInputTarget.scrollTop = 0 // Reset scroll position
    this.scrollToBottom()
    
    // Show thinking indicator
    this.showThinkingIndicator()
    
    try {
      const response = await fetch(`/chats/${this.currentChatId}/messages`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          message: { content: content }
        })
      })
      
      if (response.ok) {
        const result = await response.json()
        if (result.assistant_message) {
          // Hide thinking indicator
          this.hideThinkingIndicator()
          
          this.addMessage(result.assistant_message)
          this.scrollToBottom()
          
          // Update the chat list to reflect the new message count
          await this.updateChatList()
          
          // Update provider usage from the response data
          console.log('Updating usage from message response...')
          this.updateUsageFromResult(result)
        }
      }
    } catch (error) {
      console.error('Error sending message:', error)
      // Hide thinking indicator on error
      this.hideThinkingIndicator()
    }
  }
  
  showMessageInput() {
    this.messageInputContainerTarget.style.display = 'block'
    this.messageInputTarget.focus()
  }
  
  scrollToBottom() {
    setTimeout(() => {
      this.messagesContainerTarget.scrollTop = this.messagesContainerTarget.scrollHeight
    }, 100)
  }
  
  openSettings() {
    this.settingsModalTarget.classList.remove('hidden')
  }
  
  closeSettings() {
    this.settingsModalTarget.classList.add('hidden')
  }
  
    showThinkingIndicator() {
    const thinkingElement = document.createElement('div')
    thinkingElement.className = 'flex space-x-4 mb-4'
    thinkingElement.id = 'thinking-indicator'
    
    thinkingElement.innerHTML = `
      <div class="flex justify-start w-full">
        <div class="max-w-3xl bg-gray-100 text-gray-900 rounded-lg px-4 py-3">
          <div class="flex items-center space-x-2">
            <span class="text-gray-600 italic">Thinking</span>
            <div class="thinking-dots">
              <span class="dot">.</span>
              <span class="dot">.</span>
              <span class="dot">.</span>
            </div>
          </div>
        </div>
      </div>
    `
    
    this.messagesContainerTarget.appendChild(thinkingElement)
    this.scrollToBottom()
  }
  
  hideThinkingIndicator() {
    const thinkingElement = document.getElementById('thinking-indicator')
    if (thinkingElement) {
      thinkingElement.remove()
    }
  }
  
  async updateChatList() {
    console.log("Updating chat list...")
    try {
      const response = await fetch('/chats', {
        headers: {
          'Accept': 'application/json'
        }
      })
      if (response.ok) {
        const chats = await response.json()
        const chatList = document.getElementById('chat-list')
        if (chatList) {
          // Only update the first 8 chats (initial load)
          const initialChats = chats.slice(0, 8)
          chatList.innerHTML = initialChats.map(chat => `
            <button class="chat-item w-full text-left px-3 py-2 rounded-lg hover:bg-gray-100 transition-colors" data-chat-id="${chat.id}">
              <div class="flex items-center space-x-3">
                <div class="w-8 h-8 bg-gray-200 rounded-lg flex items-center justify-center">
                  <svg class="w-4 h-4 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path>
                  </svg>
                </div>
                <div class="flex-1 min-w-0">
                  <p class="text-sm font-medium text-gray-900 truncate">${chat.title}</p>
                  <p class="text-xs text-gray-500">${chat.message_count} message${chat.message_count !== 1 ? 's' : ''}</p>
                </div>
              </div>
            </button>
          `).join('')
          
          // Reset infinite scroll state
          this.resetInfiniteScroll()
        }
      }
    } catch (error) {
      console.error('Error updating chat list:', error)
    }
  }

  startProviderMonitoring() {
    // Check provider status every 30 seconds
    this.checkProviderStatus()
    setInterval(() => {
      this.checkProviderStatus()
    }, 30000) // 30 seconds
  }

  async checkProviderStatus() {
    try {
      const response = await fetch('/dashboard/connection_status', {
        headers: {
          'Accept': 'application/json'
        }
      })
      
      if (response.ok) {
        const status = await response.json()
        this.updateProviderIndicator(status)
      }
    } catch (error) {
      console.error('Error checking provider status:', error)
      this.updateProviderIndicator({
        status: 'disconnected',
        message: 'Connection check failed'
      })
    }
  }

  updateProviderIndicator(status) {
    const indicator = document.getElementById('provider-status-indicator')
    const requestsUsage = document.getElementById('requests-usage')
    const tokensUsage = document.getElementById('tokens-usage')
    
    if (!indicator) return

    // Update status indicator
    if (status.status === 'connected') {
      indicator.innerHTML = '<div class="w-3 h-3 bg-green-400 rounded-full animate-pulse"></div>'
    } else if (status.status === 'warning') {
      indicator.innerHTML = '<div class="w-3 h-3 bg-yellow-400 rounded-full animate-pulse"></div>'
    } else {
      indicator.innerHTML = '<div class="w-3 h-3 bg-red-400 rounded-full"></div>'
    }

    // Update usage information
    if (status.usage && requestsUsage && tokensUsage) {
      const requests = status.usage.requests
      const tokens = status.usage.tokens
      
      requestsUsage.textContent = `${requests.used}/${requests.limit}`
      tokensUsage.textContent = `${tokens.used}/${tokens.limit}`
    }
  }

  updateUsageFromResult(result) {
    console.log('Extracting usage from response data...')
    
    if (result.rate_limits) {
      const { remaining_requests, limit_requests, remaining_tokens, limit_tokens } = result.rate_limits
      
      console.log('Rate limit data:', {
        remaining_requests,
        limit_requests,
        remaining_tokens,
        limit_tokens
      })
      
      if (remaining_requests && limit_requests && remaining_tokens && limit_tokens) {
        const usedRequests = parseInt(limit_requests) - parseInt(remaining_requests)
        const usedTokens = parseInt(limit_tokens) - parseInt(remaining_tokens)
        
        const requestsUsage = document.getElementById('requests-usage')
        const tokensUsage = document.getElementById('tokens-usage')
        
        if (requestsUsage && tokensUsage) {
          requestsUsage.textContent = `${usedRequests}/${limit_requests}`
          tokensUsage.textContent = `${usedTokens}/${limit_tokens}`
          
          // Add visual feedback
          requestsUsage.style.backgroundColor = '#fef3c7'
          tokensUsage.style.backgroundColor = '#fef3c7'
          
          setTimeout(() => {
            requestsUsage.style.backgroundColor = ''
            tokensUsage.style.backgroundColor = ''
          }, 1000)
          
          console.log('Usage updated from response data:', { usedRequests, usedTokens })
        }
      }
    } else {
      console.log('Rate limit data not found in response')
    }
  }

  async updateProviderUsageAfterMessage() {
    console.log('Updating provider usage after message...')
    try {
      const response = await fetch('/dashboard/connection_status', {
        headers: {
          'Accept': 'application/json'
        }
      })
      
      if (response.ok) {
        const status = await response.json()
        console.log('Received status:', status)
        
        // Only update usage, not the status indicator
        const requestsUsage = document.getElementById('requests-usage')
        const tokensUsage = document.getElementById('tokens-usage')
        
        console.log('Found elements:', { requestsUsage, tokensUsage })
        
        if (status.usage && requestsUsage && tokensUsage) {
          const requests = status.usage.requests
          const tokens = status.usage.tokens
          
          console.log('Updating usage:', { requests, tokens })
          
          requestsUsage.textContent = `${requests.used}/${requests.limit}`
          tokensUsage.textContent = `${tokens.used}/${tokens.limit}`
          
          // Add visual feedback
          requestsUsage.style.backgroundColor = '#fef3c7'
          tokensUsage.style.backgroundColor = '#fef3c7'
          
          setTimeout(() => {
            requestsUsage.style.backgroundColor = ''
            tokensUsage.style.backgroundColor = ''
          }, 1000)
          
          console.log('Usage updated successfully')
        } else {
          console.log('Missing elements or usage data:', { 
            hasUsage: !!status.usage, 
            hasRequestsUsage: !!requestsUsage, 
            hasTokensUsage: !!tokensUsage 
          })
        }
      }
    } catch (error) {
      console.error('Error updating provider usage after message:', error)
    }
  }

  createUsageTooltip(usage) {
    const requests = usage.requests
    const tokens = usage.tokens
    
    return `API Usage:
Requests: ${requests.used}/${requests.limit} (${requests.percentage}%)
Tokens: ${tokens.used}/${tokens.limit} (${tokens.percentage}%)
Reset: ${usage.reset_requests}`
  }

  setupInfiniteScroll() {
    this.currentPage = 1
    this.isLoading = false
    this.hasMore = true
    
    const container = document.getElementById('chat-list-container')
    if (!container) return
    
    // Force scrollbar to be visible
    container.style.overflowY = 'scroll'
    
    container.addEventListener('scroll', (e) => {
      this.handleScroll(e)
    })
    
    // Log scroll container info for debugging
    console.log('Scroll container setup:', {
      element: container,
      scrollHeight: container.scrollHeight,
      clientHeight: container.clientHeight,
      hasScrollbar: container.scrollHeight > container.clientHeight
    })
  }

  handleScroll(e) {
    const container = e.target
    const scrollTop = container.scrollTop
    const scrollHeight = container.scrollHeight
    const clientHeight = container.clientHeight
    
    // Check if we're near the bottom (within 50px)
    if (scrollHeight - scrollTop - clientHeight < 50 && !this.isLoading && this.hasMore) {
      this.loadMoreChats()
    }
  }

  async loadMoreChats() {
    if (this.isLoading || !this.hasMore) return
    
    this.isLoading = true
    this.showLoadingIndicator()
    
    try {
      const response = await fetch(`/dashboard/load_more_chats?page=${this.currentPage}`, {
        headers: {
          'Accept': 'application/json'
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        this.appendChats(data.chats)
        this.hasMore = data.has_more
        this.currentPage = data.next_page
        
        if (!this.hasMore) {
          this.showEndIndicator()
        }
      }
    } catch (error) {
      console.error('Error loading more chats:', error)
    } finally {
      this.isLoading = false
      this.hideLoadingIndicator()
    }
  }

  appendChats(chats) {
    const chatList = document.getElementById('chat-list')
    if (!chatList) return
    
    chats.forEach(chat => {
      const chatElement = document.createElement('button')
      chatElement.className = 'chat-item w-full text-left px-3 py-2 rounded-lg hover:bg-gray-100 transition-colors'
      chatElement.dataset.chatId = chat.id
      
      chatElement.innerHTML = `
        <div class="flex items-center space-x-3">
          <div class="w-8 h-8 bg-gray-200 rounded-lg flex items-center justify-center">
            <svg class="w-4 h-4 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path>
            </svg>
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-gray-900 truncate">${chat.title}</p>
            <p class="text-xs text-gray-500">${chat.message_count} message${chat.message_count !== 1 ? 's' : ''}</p>
          </div>
        </div>
      `
      
      chatList.appendChild(chatElement)
    })
  }

  showLoadingIndicator() {
    const loading = document.getElementById('chat-loading')
    if (loading) {
      loading.classList.remove('hidden')
    }
  }

  hideLoadingIndicator() {
    const loading = document.getElementById('chat-loading')
    if (loading) {
      loading.classList.add('hidden')
    }
  }

  showEndIndicator() {
    const end = document.getElementById('chat-end')
    if (end) {
      end.classList.remove('hidden')
    }
  }

  resetInfiniteScroll() {
    this.currentPage = 1
    this.isLoading = false
    this.hasMore = true
    
    const end = document.getElementById('chat-end')
    if (end) {
      end.classList.add('hidden')
    }
  }
}
