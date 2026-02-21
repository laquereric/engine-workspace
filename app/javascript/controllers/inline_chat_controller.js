import { Controller } from "@hotwired/stimulus"

// Inline chat controller — fetch-based chat panel with markdown rendering.
// Used by engines that embed a chat panel with a JSON endpoint (not Turbo Streams).
//
// Required targets: messages, input
// Optional targets: welcome (removed on first message), send (disabled while sending)
// Required values:  endpoint (URL to POST { message: text } to)
export default class extends Controller {
  static targets = ["messages", "input", "welcome", "send"]
  static values = { endpoint: String }

  connect() {
    this.sending = false
  }

  send(event) {
    if (event) event.preventDefault()
    const text = this.inputTarget.value.trim()
    if (!text || this.sending) return

    this.appendMessage(text, "user")
    this.inputTarget.value = ""
    this.setEnabled(false)
    this.showThinking()

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(this.endpointValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken || ""
      },
      body: JSON.stringify({ message: text })
    })
      .then((resp) => {
        this.removeThinking()
        if (resp.ok) {
          return resp.json().then((data) => this.appendMessage(data.content, "assistant"))
        } else {
          return resp
            .json()
            .catch(() => ({ error: "Request failed" }))
            .then((err) => this.appendMessage("Error: " + (err.error || "Unexpected error"), "assistant"))
        }
      })
      .catch(() => {
        this.removeThinking()
        this.appendMessage("Error: Network request failed", "assistant")
      })
      .finally(() => this.setEnabled(true))
  }

  keydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.send()
    }
  }

  // --- DOM helpers ---

  appendMessage(text, sender) {
    if (this.hasWelcomeTarget) this.welcomeTarget.remove()

    const wrapper = document.createElement("div")
    wrapper.className = sender === "user" ? "flex justify-end" : "flex justify-start"

    const bubble = document.createElement("div")
    if (sender === "user") {
      bubble.className = "max-w-[75%] rounded-lg px-3 py-2 text-sm bg-primary-600 text-white"
      bubble.textContent = text
    } else {
      bubble.className =
        "max-w-[75%] rounded-lg px-4 py-3 bg-white border border-gray-200 text-gray-900 ds-prose ds-prose-sm"
      bubble.innerHTML = typeof DS !== "undefined" && DS.renderMarkdown ? DS.renderMarkdown(text) : text
    }

    wrapper.appendChild(bubble)
    this.messagesTarget.appendChild(wrapper)
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  showThinking() {
    const wrapper = document.createElement("div")
    wrapper.className = "flex justify-start"
    wrapper.setAttribute("data-inline-chat-role", "thinking")

    const bubble = document.createElement("div")
    bubble.className =
      "max-w-[75%] rounded-lg px-3 py-2 text-sm bg-white border border-gray-200 text-gray-400 animate-pulse"
    bubble.textContent = "Thinking..."

    wrapper.appendChild(bubble)
    this.messagesTarget.appendChild(wrapper)
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  removeThinking() {
    const el = this.element.querySelector('[data-inline-chat-role="thinking"]')
    if (el) el.remove()
  }

  setEnabled(enabled) {
    this.sending = !enabled
    this.inputTarget.disabled = !enabled
    if (this.hasSendTarget) this.sendTarget.disabled = !enabled
    if (enabled) this.inputTarget.focus()
  }
}
