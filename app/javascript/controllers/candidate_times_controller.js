import { Controller } from "@hotwired/stimulus"
import { CITY_CATALOG } from "city_catalog"

const STORAGE_KEY = "timezone-scheduler.world-clock"

export default class extends Controller {
  static targets = ["modal", "date", "time", "status", "previews", "summary", "count", "list", "reviewButton", "reviewModal", "reviewList"]
  static values = { url: String }

  connect() {
    this.candidates = []
    this.boundInstantSelected = (event) => this.openForInstant(event.detail.instant)
    window.addEventListener("world-clock:instant-selected", this.boundInstantSelected)
    this.renderCandidates()
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

  review() {
    if (this.candidates.length < 2) return

    this.reviewListTarget.replaceChildren()
    this.candidates.forEach((candidate, index) => {
      const section = document.createElement("section")
      section.className = "border-b border-slate-100 pb-3 last:border-b-0 last:pb-0"
      const heading = document.createElement("h4")
      heading.className = "text-sm font-bold text-slate-700"
      heading.textContent = `${index + 1}. ${this.format(candidate.instant, this.primaryCity().timeZone)}`
      section.append(heading)
      this.appendCityPreviews(section, candidate.instant)
      this.reviewListTarget.append(section)
    })
    this.reviewModalTarget.hidden = false
  }

  closeReview() {
    this.reviewModalTarget.hidden = true
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
    this.selectedInstant = event.currentTarget.dataset.instant
    this.renderPreviews(event.currentTarget.dataset.instant)
    this.statusTarget.textContent = ""
  }

  renderPreviews(instant) {
    this.selectedInstant = instant
    this.previewsTarget.replaceChildren()
    this.appendCityPreviews(this.previewsTarget, instant)

    const alreadySelected = this.candidates.some((candidate) => candidate.instant === instant)
    const add = document.createElement("button")
    add.type = "button"
    add.className = "mt-3 w-full rounded-lg bg-blue-700 px-3 py-2 text-sm font-bold text-white hover:bg-blue-800 disabled:cursor-not-allowed disabled:bg-slate-300 disabled:text-slate-500"
    add.textContent = alreadySelected ? "Already selected" : "Add this time"
    add.disabled = alreadySelected || this.candidates.length >= 10
    add.dataset.action = "click->candidate-times#addCandidate"
    this.previewsTarget.append(add)
  }

  appendCityPreviews(container, instant) {
    this.cities().forEach((city) => {
      const row = document.createElement("div")
      row.className = "flex items-baseline justify-between gap-3 border-b border-slate-100 py-2 last:border-b-0"
      const name = document.createElement("strong")
      name.textContent = city.name
      const time = document.createElement("span")
      time.className = "text-right text-sm text-slate-600"
      time.textContent = this.format(instant, city.timeZone)
      row.append(name, time)
      container.append(row)
    })
  }

  addCandidate() {
    if (!this.selectedInstant) return
    if (this.candidates.some((candidate) => candidate.instant === this.selectedInstant)) {
      this.statusTarget.textContent = "This time is already selected."
      return
    }
    if (this.candidates.length >= 10) {
      this.statusTarget.textContent = "You can select up to 10 times."
      return
    }

    this.candidates.push({ instant: this.selectedInstant })
    this.candidates.sort((a, b) => new Date(a.instant) - new Date(b.instant))
    this.renderCandidates()
    this.renderPreviews(this.selectedInstant)
  }

  removeCandidate(event) {
    this.candidates = this.candidates.filter((candidate) => candidate.instant !== event.currentTarget.dataset.instant)
    this.renderCandidates()
    if (this.selectedInstant) this.renderPreviews(this.selectedInstant)
  }

  renderCandidates() {
    this.summaryTarget.hidden = this.candidates.length === 0
    this.countTarget.textContent = `${this.candidates.length} of 10 times selected`
    this.reviewButtonTarget.hidden = this.candidates.length < 2
    this.reviewButtonTarget.disabled = this.candidates.length < 2
    this.listTarget.replaceChildren()
    this.candidates.forEach((candidate, index) => {
      const row = document.createElement("div")
      row.className = "flex items-center justify-start gap-3 border-b border-slate-100 py-2 last:border-b-0"
      const label = document.createElement("span")
      label.className = "w-44 shrink-0 whitespace-nowrap text-sm text-slate-700"
      label.textContent = this.format(candidate.instant, this.primaryCity().timeZone)
      const remove = document.createElement("button")
      remove.type = "button"
      remove.className = "flex h-6 w-6 shrink-0 items-center justify-center rounded-lg text-slate-400 hover:bg-slate-100 hover:text-slate-500"
      remove.dataset.instant = candidate.instant
      remove.dataset.action = "click->candidate-times#removeCandidate"
      remove.setAttribute("aria-label", `Remove selected time ${index + 1}`)
      remove.append(this.icon("trash"))
      row.append(label, remove)
      this.listTarget.append(row)
    })
  }

  icon(name) {
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    svg.setAttribute("viewBox", "0 0 24 24")
    svg.setAttribute("fill", "none")
    svg.setAttribute("stroke", "currentColor")
    svg.setAttribute("stroke-width", "1.8")
    svg.setAttribute("aria-hidden", "true")
    svg.classList.add("h-4", "w-4")

    const path = document.createElementNS("http://www.w3.org/2000/svg", "path")
    path.setAttribute("stroke-linecap", "round")
    path.setAttribute("stroke-linejoin", "round")
    path.setAttribute("d", name === "trash"
      ? "m6 7.5 1 12h10l1-12M4.5 7.5h15M9.5 7.5V5h5v2.5M10 11v5M14 11v5"
      : "")
    svg.append(path)
    return svg
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
    const date = new Intl.DateTimeFormat("en-US", {
      timeZone, weekday: "short", month: "short", day: "numeric"
    }).format(new Date(instant))
    const time = new Intl.DateTimeFormat("en-US", {
      timeZone, hour: "numeric", minute: "2-digit"
    }).format(new Date(instant))
    return `${date} at ${time}`
  }

  offsetLabel(instant, timeZone) {
    return new Intl.DateTimeFormat("en-US", { timeZone, timeZoneName: "longOffset" })
      .formatToParts(new Date(instant)).find((part) => part.type === "timeZoneName").value
  }
}
