import { Controller } from "@hotwired/stimulus"
import { CITY_CATALOG } from "city_catalog"

const MAX_CITIES = 10
const STORAGE_KEY = "timezone-scheduler.world-clock"

export default class extends Controller {
  static targets = ["cityCount", "searchPanel", "searchInput", "searchResults", "message", "addCityButton"]

  connect() {
    this.cities = this.loadCities()
    this.replacementMode = false
    this.saveCities()
    this.render()
    this.boundCloseOnEscape = (event) => {
      if (event.key === "Escape" && !this.searchPanelTarget.hidden) this.closeSearch()
    }
    document.addEventListener("keydown", this.boundCloseOnEscape)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundCloseOnEscape)
  }

  openAdd() {
    this.replacementMode = false
    this.openSearch()
  }

  openChange() {
    if (this.cities.length === 0) {
      this.showMessage("Choose your city before changing it.")
      return
    }

    this.replacementMode = true
    this.openSearch()
  }

  closeSearch() {
    this.searchPanelTarget.hidden = true
    this.searchInputTarget.value = ""
    this.renderSearchResults()
  }

  search() {
    this.renderSearchResults()
  }

  selectCity(event) {
    const city = this.cityByKey(event.currentTarget.dataset.cityKey)
    if (!city || this.cities.some((selected) => selected.key === city.key && !this.replacementMode)) return

    if (this.replacementMode) {
      const primaryIndex = this.cities.findIndex((selected) => selected.primary)
      const existingIndex = this.cities.findIndex((selected) => selected.key === city.key)

      if (existingIndex >= 0) {
        this.cities = this.cities.filter((_, index) => index !== primaryIndex)
        this.cities = this.cities.map((selected) => ({ ...selected, primary: selected.key === city.key }))
      } else {
        this.cities = this.cities.map((selected) => ({ ...selected, primary: false }))
        this.cities[primaryIndex] = { ...city, primary: true }
      }
    } else {
      if (this.cities.length >= MAX_CITIES) {
        this.showMessage(`You can add up to ${MAX_CITIES} cities.`)
        return
      }
      this.cities.push({ ...city, primary: this.cities.length === 0 })
    }

    this.cities.sort((a, b) => Number(b.primary) - Number(a.primary))
    this.replacementMode = false
    this.saveCities()
    this.closeSearch()
    this.render()
  }

  removeCity(event) {
    const key = event.currentTarget.dataset.cityKey
    const city = this.cities.find((selected) => selected.key === key)
    if (!city || city.primary) return

    this.cities = this.cities.filter((selected) => selected.key !== key)
    this.saveCities()
    this.render()
  }

  openSearch() {
    this.searchPanelTarget.hidden = false
    this.searchInputTarget.focus()
    this.renderSearchResults()
  }

  render() {
    this.cityCountTarget.textContent = `${this.cities.length} of ${MAX_CITIES} cities`
    if (this.hasAddCityButtonTarget) this.addCityButtonTarget.disabled = this.cities.length >= MAX_CITIES
    window.dispatchEvent(new CustomEvent("world-clock:cities-changed", { detail: this.cities }))
    this.renderSearchResults()
  }

  renderSearchResults() {
    if (!this.hasSearchResultsTarget) return

    const query = (this.searchInputTarget?.value || "").trim().toLocaleLowerCase()
    const selectedKeys = new Set(this.cities.map((city) => city.key))
    const results = CITY_CATALOG.filter((city) => {
      const matches = `${city.name} ${city.region}`.toLocaleLowerCase().includes(query)
      return matches && (this.replacementMode || !selectedKeys.has(city.key))
    }).slice(0, 8)

    this.searchResultsTarget.replaceChildren()
    if (results.length === 0) {
      const message = document.createElement("p")
      message.className = "text-sm text-slate-500"
      message.textContent = "No cities found."
      this.searchResultsTarget.append(message)
      return
    }

    results.forEach((city) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "grid justify-items-start rounded-lg bg-slate-50 px-3 py-3 text-left text-slate-900 hover:bg-slate-100"
      button.dataset.cityKey = city.key
      button.dataset.action = "click->world-clock#selectCity"
      button.setAttribute("aria-label", `${this.replacementMode ? "Change to" : "Add"} ${city.name}`)
      button.innerHTML = `<strong>${this.escapeHtml(city.name)}</strong><span class="text-sm text-slate-500">${this.escapeHtml(city.region)} · ${this.escapeHtml(city.timeZone)}</span>`
      this.searchResultsTarget.append(button)
    })
  }

  cityCard(city) {
    const card = document.createElement("article")
    card.className = "flex w-full items-center justify-between gap-4 border-b border-slate-200 py-4 last:border-b-0"
    const now = new Intl.DateTimeFormat("en-US", {
      timeZone: city.timeZone,
      month: "short",
      day: "numeric",
      hour: "numeric",
      minute: "2-digit"
    }).format(new Date())
    card.innerHTML = `<div><p class="font-bold">${this.escapeHtml(city.name)} ${city.primary ? '<span class="ml-1 text-xs font-extrabold uppercase tracking-wide text-indigo-600">Your city</span>' : ""}</p><p class="text-sm text-slate-500">${this.escapeHtml(city.region)}</p><time class="text-sm text-slate-500" datetime="${new Date().toISOString()}">${this.escapeHtml(now)}</time></div>`

    const action = document.createElement("button")
    action.type = "button"
    action.className = "rounded-lg px-2 py-1 text-sm font-bold text-blue-700 hover:bg-blue-50 focus:outline-none focus:ring-2 focus:ring-blue-500"

    if (city.primary) {
      action.dataset.action = "click->world-clock#openChange"
      action.setAttribute("aria-label", "Change your city")
      action.textContent = "Change"
    } else {
      action.dataset.cityKey = city.key
      action.dataset.action = "click->world-clock#removeCity"
      action.textContent = "Remove"
    }

    card.append(action)
    return card
  }

  loadCities() {
    let stored
    try {
      stored = JSON.parse(window.localStorage.getItem(STORAGE_KEY))
    } catch (_error) {
      stored = null
    }

    if (Array.isArray(stored)) {
      const valid = stored
        .map((city) => this.cityByKey(city?.key))
        .filter(Boolean)
        .filter((city, index, cities) => cities.findIndex((item) => item.key === city.key) === index)
        .slice(0, MAX_CITIES)
      const storedPrimary = stored.find((city) => city?.primary)?.key
      const primaryKey = storedPrimary && valid.some((city) => city.key === storedPrimary) ? storedPrimary : valid[0]?.key
      if (valid.length > 0) {
        return valid
          .map((city) => ({ ...city, primary: city.key === primaryKey }))
          .sort((a, b) => Number(b.primary) - Number(a.primary))
      }
    }

    const browserTimeZone = Intl.DateTimeFormat().resolvedOptions().timeZone
    const detected = CITY_CATALOG.find((city) => city.timeZone === browserTimeZone)
    return detected ? [{ ...detected, primary: true }] : []
  }

  saveCities() {
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(this.cities))
    } catch (_error) {
      this.showMessage("Your browser could not save this city list, but you can keep using it for now.")
    }
  }

  cityByKey(key) {
    return CITY_CATALOG.find((city) => city.key === key)
  }

  showMessage(message) {
    if (this.hasMessageTarget) this.messageTarget.textContent = message
  }

  escapeHtml(value) {
    const element = document.createElement("span")
    element.textContent = value
    return element.innerHTML
  }
}
