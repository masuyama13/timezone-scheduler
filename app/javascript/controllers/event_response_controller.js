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

    const body = new URLSearchParams()
    body.set("name", this.nameTarget.value)
    body.set("time_zone", this.timeZoneTarget.value)
    body.set("comment", this.commentTarget.value)

    this.element.querySelectorAll("[data-time-option-id]").forEach((option, index) => {
      const selected = option.querySelector("input[type=radio]:checked")
      body.set(`choices[${index}][time_option_id]`, option.dataset.timeOptionId)
      body.set(`choices[${index}][availability]`, selected?.value || "")
    })

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: { Accept: "application/json" },
        body
      })
      const data = await response.json()
      if (!response.ok) throw new Error(data.errors?.join(" ") || "Could not submit your availability. Please try again.")

      this.formTarget.reset()
      this.statusTarget.className = "text-sm text-emerald-700"
      this.statusTarget.textContent = "Availability submitted."
    } catch (error) {
      this.statusTarget.className = "text-sm text-amber-700"
      this.statusTarget.textContent = error.message
    } finally {
      this.submitTarget.disabled = false
    }
  }
}
