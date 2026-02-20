import { Controller } from "@hotwired/stimulus"

// Accordion controller — manages expand/collapse, state persistence, single-open mode.
// Works with native <details>/<summary> elements for zero-JS baseline.
export default class extends Controller {
  static targets = ["panel"]
  static values = {
    singleOpen: { type: Boolean, default: false },
    persistState: { type: Boolean, default: true }
  }

  connect() {
    this.restoreState()
  }

  toggle(event) {
    const panel = event.currentTarget.closest("details")
    if (!panel) return

    if (this.singleOpenValue && !panel.open) {
      // Close all other panels when opening this one
      this.panelTargets.forEach((p) => {
        if (p !== panel) p.removeAttribute("open")
      })
    }

    // Let the browser toggle the clicked panel, then persist
    requestAnimationFrame(() => this.saveState())
  }

  expandAll() {
    this.panelTargets.forEach((p) => p.setAttribute("open", ""))
    this.saveState()
  }

  collapseAll() {
    this.panelTargets.forEach((p) => p.removeAttribute("open"))
    this.saveState()
  }

  // --- State persistence ---

  saveState() {
    if (!this.persistStateValue) return

    const openIds = this.panelTargets
      .filter((p) => p.open)
      .map((p) => p.dataset.panelId)

    try {
      localStorage.setItem(this.storageKey, JSON.stringify(openIds))
    } catch (_) {
      // localStorage unavailable — ignore
    }
  }

  restoreState() {
    if (!this.persistStateValue) return

    let openIds
    try {
      openIds = JSON.parse(localStorage.getItem(this.storageKey))
    } catch (_) {
      return
    }

    if (!Array.isArray(openIds)) return

    this.panelTargets.forEach((panel) => {
      const id = panel.dataset.panelId
      if (openIds.includes(id)) {
        panel.setAttribute("open", "")
      } else {
        panel.removeAttribute("open")
      }
    })
  }

  get storageKey() {
    return `workspace-accordion-${window.location.pathname}`
  }
}
