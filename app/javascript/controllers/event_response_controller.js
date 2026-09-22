import { Controller } from "@hotwired/stimulus"
import { CITY_CATALOG } from "city_catalog"

export default class extends Controller {
  static targets = [
    "form", "name", "timeZone", "timeZoneButton", "timeZoneLabel", "displayTimeZone",
    "timeZoneDialog", "timeZoneSearch", "timeZoneResults", "responseDate", "optionDate",
    "comment", "submit", "submitLabel", "status", "responseDialog", "modalTitle"
  ]
  static values = { url: String, updateUrlTemplate: String, fallbackTimeZone: String }

  connect() {
    this.editingResponseId = null
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
    this.updateTimeZoneLabel()
    this.updateDisplayedTimes()
    this.renderTimeZoneResults()
  }

  openTimeZoneSearch() {
    this.timeZoneDialogTarget.hidden = false
    this.timeZoneSearchTarget.focus()
    this.renderTimeZoneResults()
  }

  closeTimeZoneSearch() {
    this.timeZoneDialogTarget.hidden = true
    this.timeZoneSearchTarget.value = ""
    this.renderTimeZoneResults()
  }

  searchTimeZones() {
    this.renderTimeZoneResults()
  }

  selectTimeZone(event) {
    this.timeZoneTarget.value = event.currentTarget.dataset.timeZone
    this.updateTimeZoneLabel()
    this.updateDisplayedTimes()
    this.closeTimeZoneSearch()
  }

  openCreate() {
    this.editingResponseId = null
    this.resetResponseForm()
    this.modalTitleTarget.textContent = "Add your availability"
    this.submitLabelTarget.textContent = "Add response"
    this.responseDialogTarget.hidden = false
    this.nameTarget.focus()
  }

  edit(event) {
    const button = event.currentTarget
    this.editingResponseId = button.dataset.responseId
    this.nameTarget.value = button.dataset.responseName || ""
    this.commentTarget.value = button.dataset.responseComment || ""
    if (button.dataset.responseTimeZone) this.timeZoneTarget.value = button.dataset.responseTimeZone
    this.updateTimeZoneLabel()
    this.updateDisplayedTimes()

    this.formTarget.querySelectorAll('input[type="radio"]').forEach((input) => { input.checked = false })
    const choices = JSON.parse(button.dataset.responseChoices || "{}")
    this.formTarget.querySelectorAll("[data-time-option-id]").forEach((option) => {
      const availability = choices[option.dataset.timeOptionId]
      const input = availability && Array.from(option.querySelectorAll('input[type="radio"]')).find((candidate) => candidate.value === availability)
      if (input) input.checked = true
    })

    this.statusTarget.textContent = ""
    this.modalTitleTarget.textContent = "Edit your response"
    this.submitLabelTarget.textContent = "Save changes"
    this.responseDialogTarget.hidden = false
    this.nameTarget.focus()
  }

  closeResponseModal() {
    this.responseDialogTarget.hidden = true
    this.resetResponseForm()
  }

  resetResponseForm() {
    this.formTarget.reset()
    this.statusTarget.textContent = ""
    this.statusTarget.className = "text-sm text-amber-700"
  }

  updateDisplayedTimes() {
    const timeZone = this.timeZoneTarget.value
    this.responseDateTargets.forEach((element) => {
      element.textContent = this.formatDate(element.dataset.instant, timeZone)
    })
    this.optionDateTargets.forEach((element) => {
      element.textContent = this.formatOptionDate(element.dataset.instant, timeZone)
    })
  }

  formatDate(instant, timeZone) {
    return new Intl.DateTimeFormat("en-US", { timeZone, month: "short", day: "numeric", year: "numeric", hour: "numeric", minute: "2-digit" }).format(new Date(instant))
  }

  formatOptionDate(instant, timeZone) {
    return new Intl.DateTimeFormat("en-US", { timeZone, weekday: "short", month: "short", day: "numeric", year: "numeric", hour: "numeric", minute: "2-digit" }).format(new Date(instant))
  }

  updateTimeZoneLabel() {
    const city = CITY_CATALOG.find((item) => item.timeZone === this.timeZoneTarget.value)
    const label = city ? `${city.name} (${city.timeZone})` : this.timeZoneTarget.value
    this.timeZoneLabelTarget.textContent = label
    this.displayTimeZoneTarget.textContent = label
  }

  renderTimeZoneResults() {
    if (!this.hasTimeZoneResultsTarget) return
    const query = (this.timeZoneSearchTarget?.value || "").trim().toLocaleLowerCase()
    const results = CITY_CATALOG.filter((city) => `${city.name} ${city.region} ${city.timeZone}`.toLocaleLowerCase().includes(query)).slice(0, 8)
    this.timeZoneResultsTarget.replaceChildren()
    if (results.length === 0) {
      const message = document.createElement("p")
      message.className = "text-sm text-slate-500"
      message.textContent = "No cities found."
      this.timeZoneResultsTarget.append(message)
      return
    }
    results.forEach((city) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "grid justify-items-start rounded-lg bg-slate-50 px-3 py-3 text-left text-slate-900 hover:bg-slate-100"
      button.dataset.timeZone = city.timeZone
      button.dataset.action = "click->event-response#selectTimeZone"
      button.innerHTML = `<strong>${this.escapeHtml(city.name)}</strong><span class="text-sm text-slate-500">${this.escapeHtml(city.region)} · ${this.escapeHtml(city.timeZone)}</span>`
      this.timeZoneResultsTarget.append(button)
    })
  }

  escapeHtml(value) {
    return value.replace(/[&<>'"]/g, (character) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", '"': "&quot;" })[character])
  }

  async submit(event) {
    event.preventDefault()
    this.submitTarget.disabled = true
    this.statusTarget.textContent = ""

    const choices = []
    this.formTarget.querySelectorAll("[data-time-option-id]").forEach((option) => {
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
    const editing = Boolean(this.editingResponseId)
    const url = editing ? this.updateUrlTemplateValue.replace("RESPONSE_ID", this.editingResponseId) : this.urlValue

    try {
      const response = await fetch(url, {
        method: editing ? "PATCH" : "POST",
        headers: { Accept: "application/json", "Content-Type": "application/json" },
        body
      })
      const data = await response.json()
      if (!response.ok) throw new Error(data.errors?.join(" ") || "Could not save your availability. Please try again.")

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
