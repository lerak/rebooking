import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messageThread", "messageFormContainer"]

  connect() {
    // Request notification permission on load
    this.requestNotificationPermission()

    // Scroll to bottom of message thread when new messages arrive
    if (this.hasMessageThreadTarget) {
      this.scrollToBottom()
    }

    // Listen for Turbo Stream updates to show notifications
    document.addEventListener('turbo:before-stream-render', this.handleNewMessage.bind(this))
  }

  disconnect() {
    document.removeEventListener('turbo:before-stream-render', this.handleNewMessage.bind(this))
  }

  handleNewMessage(event) {
    // Check if this is a new inbound message
    const streamAction = event.target.getAttribute('action')
    const target = event.target.getAttribute('target')

    if (streamAction === 'append' && target === 'messages') {
      // Extract message data from the stream
      const template = event.target.querySelector('template')
      if (template) {
        const content = template.content
        const messageElement = content.querySelector('[data-direction="inbound"]')

        if (messageElement) {
          const messageBody = messageElement.querySelector('[data-message-body]')?.textContent
          if (messageBody) {
            this.showNotification({ body: messageBody })
          }
        }
      }
    }
  }

  selectConversation(event) {
    const conversationElement = event.currentTarget
    const customerId = conversationElement.dataset.customerId

    // Remove active state from all conversations
    document.querySelectorAll('[data-customer-id]').forEach(el => {
      el.classList.remove('bg-blue-50', 'border-l-4', 'border-blue-500')
    })

    // Add active state to selected conversation
    conversationElement.classList.add('bg-blue-50', 'border-l-4', 'border-blue-500')

    // Load messages for this customer
    this.loadMessages(customerId)

    // Show message form
    if (this.hasMessageFormContainerTarget) {
      this.messageFormContainerTarget.classList.remove('hidden')
    }
  }

  loadMessages(customerId) {
    // Fetch and display messages for the selected customer
    fetch(`/messages?customer_id=${customerId}`, {
      headers: {
        'Accept': 'text/vnd.turbo-stream.html'
      }
    })
    .then(response => response.text())
    .then(html => {
      if (this.hasMessageThreadTarget) {
        this.messageThreadTarget.innerHTML = html
        this.scrollToBottom()
      }
    })
  }

  scrollToBottom() {
    if (this.hasMessageThreadTarget) {
      this.messageThreadTarget.scrollTop = this.messageThreadTarget.scrollHeight
    }
  }

  requestNotificationPermission() {
    if ("Notification" in window && Notification.permission === "default") {
      Notification.requestPermission()
    }
  }

  showNotification(message) {
    if ("Notification" in window && Notification.permission === "granted") {
      new Notification("New Message", {
        body: message.body,
        icon: "/icon.png"
      })
    }
  }
}
