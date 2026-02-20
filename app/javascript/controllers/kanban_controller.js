import { Controller } from "@hotwired/stimulus"

// Kanban controller — card navigation to planner assertion detail.
export default class extends Controller {
  navigate(event) {
    const card = event.currentTarget
    const assertionId = card.dataset.kanbanAssertionId
    if (!assertionId) return

    // Navigate to the planner assertion detail page.
    // The planner engine mounts at /planner — assertions are nested under plans.
    // For now, use a simple path that the planner routes can resolve.
    const path = `/planner/assertions/${assertionId}`
    window.Turbo ? window.Turbo.visit(path) : (window.location.href = path)
  }
}
