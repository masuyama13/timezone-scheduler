import { Controller } from "@hotwired/stimulus"
import { CITY_CATALOG } from "city_catalog"

export default class extends Controller {
  static targets = ["form", "name", "timeZone", "comment", "submit", "status"]
  static values = { url: String, fallbackTimeZone: String }

  connect() {
    this.populateTimeZones()
  }

  populateTimeZones() {
    this.timeZoneTarget.replaceChildren()
    CITY_CATALOG.forEach((city) => {
      const option = document.createElement("option")
      option.value = city.timeZone
      option.textContent = `${city.name} (${city.timeZone})`
      this.timeZoneTarget.append(option)
    })

    let browserTimeZone
    try {
      browserTimeZone = Intl.DateTimeFormat().resolvedOptions().timeZone
    } catch (_error) {
      browserTimeZone = null
    }

    const availableTimeZones = new Set(CITY_CATALOG.map((city) => city.timeZone))
    const selectedTimeZone = availableTimeZones.has(browserTimeZone)
      ? browserTimeZone
      : availableTimeZones.has(this.fallbackTimeZoneValue)
        ? this.fallbackTimeZoneValue
        : CITY_CATALOG[0]?.timeZone

    if (selectedTimeZone) this.timeZoneTarget.value = selectedTimeZone
  }

  async submit(event) {
    event.preventDefault()
    this.submitTarget.disabled = true
    this.statusTarget.textContent = ""

    const choices = []
    this.element.querySelectorAll("[data-time-option-id]").forEach((option) => {
      const selected = option.querySelector("input[type=radio]:checked")
      choices.push({
        time_option_id: option.dataset.timeOptionId,
        availability: selected?.value || ""
      })
    })

    const body = JSON.stringify({
      name: this.nameTarget.value,
      time_zone: this.timeZoneTarget.value,
      comment: this.commentTarget.value,
      choices
    })

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: { Accept: "application/json", "Content-Type": "application/json" },
        body
      })
      const data = await response.json()
      if (!response.ok) throw new Error(data.errors?.join(" ") || "Could not submit your availability. Please try again.")

      window.scrollTo(0, 0)
      window.location.assign(window.location.href)
    } catch (error) {
      this.statusTarget.className = "text-sm text-amber-700"
      this.statusTarget.textContent = error.message
    } finally {
      this.submitTarget.disabled = false
    }
  }
}
