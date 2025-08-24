import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messagesContainer", "messageInput", "messageInputContainer", "chatTitle", "chatSubtitle", "sendBtn", "settingsModal"]
  
  connect() {
    this.currentChatId = null
    this.setupEventListeners()
    this.setupAutoResize()
  }
  
  setupEventListeners() {
    // New chat button
    document.getElementById('new-chat-btn').addEventListener('click', () => {
      this.createNewChat()
    })
    
    // Start chat button
    document.getElementById('start-chat-btn').addEventListener('click', () => {
      this.createNewChat()
    })
    
    // Chat item clicks
    document.querySelectorAll('.chat-item').forEach(item => {
      item.addEventListener('click', (e) => {
        const chatId = e.currentTarget.dataset.chatId
        this.loadChat(chatId)
      })
    })
    
    // Send button
    this.sendBtnTarget.addEventListener('click', () => {
      this.sendMessage()
    })
    
    // Enter key in message input
    this.messageInputTarget.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault()
        this.sendMessage()
      }
    })
    
    // Settings modal
    document.getElementById('settings-btn').addEventListener('click', () => {
      this.openSettings()
    })
    
    document.getElementById('close-settings').addEventListener('click', () => {
      this.closeSettings()
    })
    
    // Close modal on backdrop click
    this.settingsModalTarget.addEventListener('click', (e) => {
      if (e.target === this.settingsModalTarget) {
        this.closeSettings()
      }
    })
  }
  
  setupAutoResize() {
    this.messageInputTarget.addEventListener('input', () => {
      this.messageInputTarget.style.height = 'auto'
      this.messageInputTarget.style.height = this.messageInputTarget.scrollHeight + 'px'
    })
  }
  
  async createNewChat() {
    try {
      const response = await fetch('/chats', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
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
        this.loadChat(chat.id)
        this.updateChatList()
      }
    } catch (error) {
      console.error('Error creating chat:', error)
    }
  }
  
  async loadChat(chatId) {
    try {
      const response = await fetch(`/chats/${chatId}`)
      if (response.ok) {
        const chat = await response.json()
        this.currentChatId = chatId
        this.displayChat(chat)
        this.showMessageInput()
      }
    } catch (error) {
      console.error('Error loading chat:', error)
    }
  }
  
  displayChat(chat) {
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
    try {
      const response = await fetch('/chats')
      if (response.ok) {
        const chats = await response.json()
        // Update chat list in sidebar
        const chatList = document.getElementById('chat-list')
        // Implementation for updating chat list
      }
    } catch (error) {
      console.error('Error updating chat list:', error)
    }
  }
}
