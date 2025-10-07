import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit"]

  connect() {
    // Focus on input when form loads
    if (this.hasInputTarget) {
      this.inputTarget.focus()
    }
  }

  handleKeydown(event) {
    // Submit form on Enter (without Shift)
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.submitForm()
    }
  }

  submitForm() {
    if (this.hasSubmitTarget && this.inputTarget.value.trim() !== "") {
      this.submitTarget.click()
    }
  }

  reset(event) {
    // Clear the form after successful submission
    if (event.detail.success) {
      if (this.hasInputTarget) {
        this.inputTarget.value = ""
        this.inputTarget.focus()
      }
    }
  }
}
