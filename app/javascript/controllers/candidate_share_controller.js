import { Controller } from "@hotwired/stimulus"
import { CITY_CATALOG } from "city_catalog"

export default class extends Controller {
  static targets = ["dialog", "date", "times"]
  static values = { eventName: String, eventTimeZone: String, respondentTimeZones: Array }

  connect() {
    this.selectedInstant = null
  }

  highlightColumn(event) {
    this.columnElements(event.currentTarget).forEach((element) => element.classList.add("bg-blue-50"))
  }

  unhighlightColumn(event) {
    this.columnElements(event.currentTarget).forEach((element) => element.classList.remove("bg-blue-50"))
  }

  activate(event) {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault()
      this.select(event)
    }
  }

  select(event) {
    this.selectedInstant = event.currentTarget.dataset.instant
    this.dateTarget.textContent = this.formatDate(this.selectedInstant, this.viewerTimeZone())
    this.renderTimes()
    this.dialogTarget.hidden = false
  }

  close() {
    this.dialogTarget.hidden = true
    this.selectedInstant = null
    this.timesTarget.replaceChildren()
  }

  columnElements(element) {
    return this.element.querySelectorAll(`[data-candidate-share-column-index="${element.dataset.candidateShareColumnIndex}"]`)
  }

  viewerTimeZone() {
    return this.element.closest("main")?.querySelector('[data-event-response-target="timeZone"]')?.value || this.eventTimeZoneValue
  }

  timeZones() {
    const zones = [this.viewerTimeZone(), ...this.respondentTimeZonesValue]
    return [...new Set(zones.filter(Boolean))]
  }

  renderTimes() {
    this.timesTarget.replaceChildren()
    this.timeZones().forEach((timeZone) => {
      const row = document.createElement("p")
      row.className = "text-sm text-slate-700"
      row.textContent = `${this.cityName(timeZone)}: ${this.formatDate(this.selectedInstant, timeZone)}`
      this.timesTarget.append(row)
    })
  }

  cityName(timeZone) {
    return CITY_CATALOG.find((city) => city.timeZone === timeZone)?.name || timeZone
  }

  formatDate(instant, timeZone) {
    const date = new Intl.DateTimeFormat("en-US", {
      timeZone,
      weekday: "short",
      month: "short",
      day: "numeric",
      year: "numeric",
      hour: "numeric",
      minute: "2-digit"
    }).format(new Date(instant))
    return date.replace(", ", ", ").replace(/, (?=\d{1,2}:)/, " at ")
  }
}
