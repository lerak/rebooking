import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["container", "backdrop"]

  connect() {
    // Close modal on escape key
    this.escapeHandler = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.escapeHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this.escapeHandler)
  }

  open(event) {
    event.preventDefault()
    this.containerTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }
    this.containerTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  closeOnBackdrop(event) {
    // Only close if clicking directly on the backdrop, not on modal content
    if (event.target === this.backdropTarget) {
      this.close(event)
    }
  }

  handleEscape(event) {
    if (event.key === "Escape" && !this.containerTarget.classList.contains("hidden")) {
      this.close()
    }
  }
}
