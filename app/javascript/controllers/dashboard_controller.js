import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messagesContainer", "messageInput", "messageInputContainer", "chatTitle", "chatSubtitle", "sendBtn", "settingsModal"]
  
  connect() {
    console.log("Dashboard controller connected!")
    this.currentChatId = null
    this.setupEventListeners()
    this.setupAutoResize()
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
      this.messageInputTarget.addEventListener('input', () => {
        this.messageInputTarget.style.height = 'auto'
        this.messageInputTarget.style.height = this.messageInputTarget.scrollHeight + 'px'
      })
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
          <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
          </svg>
        </div>
        <h3 class="text-lg font-medium text-gray-900 mb-2">New Chat Started</h3>
        <p class="text-gray-500">Start typing to begin your conversation with AI</p>
      </div>
    `
  }
  
  addMessage(message) {
    const messageElement = document.createElement('div')
    messageElement.className = 'flex space-x-4'
    
    const isUser = message.role === 'user'
    const alignment = isUser ? 'justify-end' : 'justify-start'
    const bgColor = isUser ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-900'
    
    messageElement.innerHTML = `
      <div class="flex ${alignment} w-full">
        <div class="max-w-3xl ${bgColor} rounded-lg px-4 py-2">
          <div class="text-sm font-medium mb-1">${message.role.charAt(0).toUpperCase() + message.role.slice(1)}</div>
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
    
    // Clear input and scroll
    this.messageInputTarget.value = ''
    this.messageInputTarget.style.height = 'auto'
    this.scrollToBottom()
    
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
          this.addMessage(result.assistant_message)
          this.scrollToBottom()
        }
      }
    } catch (error) {
      console.error('Error sending message:', error)
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
          chatList.innerHTML = chats.map(chat => `
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
        }
      }
    } catch (error) {
      console.error('Error updating chat list:', error)
    }
  }
}
