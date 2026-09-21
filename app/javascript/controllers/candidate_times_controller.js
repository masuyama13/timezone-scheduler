import { Controller } from "@hotwired/stimulus"
import { CITY_CATALOG } from "city_catalog"

const STORAGE_KEY = "timezone-scheduler.world-clock"

export default class extends Controller {
  static targets = ["modal", "date", "time", "status", "previews"]
  static values = { url: String }

  connect() {
    this.boundInstantSelected = (event) => this.openForInstant(event.detail.instant)
    window.addEventListener("world-clock:instant-selected", this.boundInstantSelected)
  }

  disconnect() {
    window.removeEventListener("world-clock:instant-selected", this.boundInstantSelected)
    this.request?.abort()
  }

  openForInstant(instant) {
    this.open()
    const city = this.primaryCity()
    if (!city) return

    const dateTime = new Intl.DateTimeFormat("en-CA", {
      timeZone: city.timeZone,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      hourCycle: "h23"
    }).formatToParts(new Date(instant))
    const values = Object.fromEntries(dateTime.map(({ type, value }) => [type, value]))
    this.dateTarget.value = `${values.year}-${values.month}-${values.day}`
    this.timeTarget.value = `${values.hour}:${values.minute}`
    this.preview()
  }

  open() {
    this.modalTarget.hidden = false
    this.statusTarget.textContent = ""
    this.previewsTarget.replaceChildren()
  }

  close() {
    this.request?.abort()
    this.modalTarget.hidden = true
  }

  async preview() {
    const city = this.primaryCity()
    if (!city || !this.dateTarget.value || !this.timeTarget.value) return

    this.request?.abort()
    const request = new AbortController()
    this.request = request
    this.statusTarget.textContent = ""
    this.previewsTarget.replaceChildren()
    try {
      const url = new URL(this.urlValue, window.location.origin)
      url.search = new URLSearchParams({ date: this.dateTarget.value, time: this.timeTarget.value, time_zone: city.timeZone })
      const response = await fetch(url, { signal: request.signal, headers: { Accept: "application/json" } })
      if (!response.ok) throw new Error("Time resolution failed")
      const data = await response.json()
      if (request.signal.aborted) return
      if (data.instants.length === 0) {
        this.statusTarget.textContent = "This local time does not exist on the selected date."
        return
      }
      if (data.instants.length > 1) {
        this.statusTarget.textContent = "This local time occurs twice. Choose an occurrence."
        data.instants.forEach((instant, index) => {
          const button = document.createElement("button")
          button.type = "button"
          button.className = "rounded-lg border border-slate-300 px-3 py-2 text-left text-sm hover:bg-slate-50"
          button.textContent = `Occurrence ${index + 1} (${this.offsetLabel(instant, city.timeZone)})`
          button.dataset.instant = instant
          button.dataset.action = "click->candidate-times#chooseOccurrence"
          this.previewsTarget.append(button)
        })
        return
      }
      this.renderPreviews(data.instants[0])
    } catch (error) {
      if (!request.signal.aborted) this.statusTarget.textContent = "Could not resolve this local time. Please try again."
    }
  }

  chooseOccurrence(event) {
    this.renderPreviews(event.currentTarget.dataset.instant)
    this.statusTarget.textContent = ""
  }

  renderPreviews(instant) {
    this.previewsTarget.replaceChildren()
    this.cities().forEach((city) => {
      const row = document.createElement("div")
      row.className = "flex items-baseline justify-between gap-3 border-b border-slate-100 py-2 last:border-b-0"
      const name = document.createElement("strong")
      name.textContent = city.name
      const time = document.createElement("span")
      time.className = "text-right text-sm text-slate-600"
      time.textContent = this.format(instant, city.timeZone)
      row.append(name, time)
      this.previewsTarget.append(row)
    })
  }

  primaryCity() { return this.cities().find((city) => city.primary) || this.cities()[0] }

  cities() {
    try {
      const stored = JSON.parse(window.localStorage.getItem(STORAGE_KEY))
      return (Array.isArray(stored) ? stored : [])
        .map((city) => ({ ...CITY_CATALOG.find((item) => item.key === city?.key), primary: city?.primary === true }))
        .filter((city) => city.key)
    } catch (_error) {
      return []
    }
  }

  format(instant, timeZone) {
    return new Intl.DateTimeFormat("en-US", {
      timeZone, weekday: "short", month: "short", day: "numeric", hour: "numeric", minute: "2-digit"
    }).format(new Date(instant))
  }

  offsetLabel(instant, timeZone) {
    return new Intl.DateTimeFormat("en-US", { timeZone, timeZoneName: "longOffset" })
      .formatToParts(new Date(instant)).find((part) => part.type === "timeZoneName").value
  }
}
