import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["url", "status"]
  static values = { url: String }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.urlValue)
      this.statusTarget.textContent = "Link copied."
    } catch (_error) {
      this.statusTarget.textContent = "Could not copy the link. Please copy it manually."
    }
  }
}
