import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]

  connect() {
    console.log("Conversation controller connected")
  }

  load(event) {
    event.preventDefault()
    const url = event.currentTarget.href

    console.log("Loading conversation from:", url)

    fetch(url, {
      headers: {
        'Accept': 'text/vnd.turbo-stream.html'
      }
    })
    .then(response => response.text())
    .then(html => {
      console.log("Received response:", html.substring(0, 100))
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error("Error loading conversation:", error)
    })
  }

  handleOutsideClick(event) {
    const formContainer = document.getElementById('message-form-container')
    const messageThread = document.getElementById('message-thread')

    // Check if form is visible and has content
    if (!formContainer || !formContainer.innerHTML.trim()) {
      return
    }

    // Check if click is outside both the form and message thread content
    if (!formContainer.contains(event.target) &&
        !messageThread.querySelector('.border-b.border-gray-300')?.contains(event.target) &&
        !event.target.closest('[data-controller="conversation"]')?.querySelector('a')) {
      this.close()
    }
  }

  close() {
    // Clear the message thread
    const messageThread = document.getElementById('message-thread')
    if (messageThread) {
      messageThread.innerHTML = `
        <div class="text-center text-gray-600 mt-20" role="status">
          <p>Select a conversation to view messages</p>
        </div>
      `
    }

    // Clear the message form
    const formContainer = document.getElementById('message-form-container')
    if (formContainer) {
      formContainer.innerHTML = ''
    }
  }
}
