import { Controller } from "@hotwired/stimulus"

// Chat controller — auto-scroll, auto-resize textarea, Enter-to-submit.
export default class extends Controller {
  static targets = ["messages", "input", "form"]

  connect() {
    this.scrollToBottom()
    this.observeMessages()
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }

  // Submit on Enter (Shift+Enter for newline)
  keydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.submit()
    }
  }

  submit() {
    const input = this.inputTarget
    if (input.value.trim() === "") return

    this.formTarget.requestSubmit()

    // Clear input after submit
    requestAnimationFrame(() => {
      input.value = ""
      this.autoResize()
    })
  }

  // Auto-resize textarea as user types
  autoResize() {
    const input = this.inputTarget
    input.style.height = "auto"
    input.style.height = Math.min(input.scrollHeight, 120) + "px"
  }

  // Scroll message list to bottom
  scrollToBottom() {
    if (!this.hasMessagesTarget) return
    const el = this.messagesTarget
    el.scrollTop = el.scrollHeight
  }

  // Watch for new messages (Turbo Stream appends) and auto-scroll
  observeMessages() {
    if (!this.hasMessagesTarget) return

    this.observer = new MutationObserver(() => this.scrollToBottom())
    this.observer.observe(this.messagesTarget, { childList: true, subtree: true })
  }
}
