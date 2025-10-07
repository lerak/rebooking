import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="nav"
export default class extends Controller {
  static targets = ["link"]

  connect() {
    this.setActiveLink()
    // Listen for Turbo navigation events to update active link
    document.addEventListener("turbo:load", this.setActiveLink.bind(this))
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.setActiveLink.bind(this))
  }

  setActiveLink() {
    const currentPath = window.location.pathname

    this.linkTargets.forEach(link => {
      const linkPath = new URL(link.href).pathname

      if (linkPath === currentPath) {
        this.activateLink(link)
      } else {
        this.deactivateLink(link)
      }
    })
  }

  activateLink(link) {
    // Remove hover classes and add active state
    link.classList.remove("text-gray-medium", "hover:bg-dark-blue", "hover:text-white")
    link.classList.add("bg-dark-blue", "text-white")
  }

  deactivateLink(link) {
    // Remove active state and restore hover classes
    link.classList.remove("bg-dark-blue", "text-white")
    link.classList.add("text-gray-medium", "hover:bg-dark-blue", "hover:text-white")
  }
}
