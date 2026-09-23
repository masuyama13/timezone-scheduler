import { Controller } from "@hotwired/stimulus"
import { CITY_CATALOG } from "city_catalog"

const STORAGE_KEY = "timezone-scheduler.world-clock"

export default class extends Controller {
  static targets = ["grid", "navigation", "dateControls", "dateInput", "status", "retry"]
  static values = { url: String }

  connect() {
    this.mobileHourOffset = 0
    this.instants = []
    this.cities = this.loadCities()
    this.boundCitiesChanged = (event) => {
      this.cities = event.detail || this.loadCities()
      this.refresh()
    }
    window.addEventListener("world-clock:cities-changed", this.boundCitiesChanged)
    this.boundResize = () => this.render()
    window.addEventListener("resize", this.boundResize)
    this.refresh()
  }

  disconnect() {
    this.request?.abort()
    window.removeEventListener("world-clock:cities-changed", this.boundCitiesChanged)
    window.removeEventListener("resize", this.boundResize)
  }

  loadCities() {
    try {
      const stored = JSON.parse(window.localStorage.getItem(STORAGE_KEY))
      if (Array.isArray(stored)) {
        return stored
          .map((city) => CITY_CATALOG.find((catalogCity) => catalogCity.key === city?.key))
          .filter(Boolean)
          .filter((city, index, cities) => cities.findIndex((item) => item.key === city.key) === index)
          .slice(0, 10)
          .map((city, index) => ({ ...city, primary: stored[index]?.primary === true }))
      }
    } catch (_error) {
      return []
    }

    return []
  }

  primaryCity() {
    return this.cities.find((city) => city.primary) || this.cities[0]
  }

  async refresh() {
    this.request?.abort()
    const primary = this.primaryCity()
    this.dateControlsTarget.hidden = !primary
    this.dateControlsTarget.classList.toggle("flex", Boolean(primary))
    this.retryTarget.hidden = true
    this.statusTarget.textContent = ""
    if (!primary) {
      this.instants = []
      this.loadedKey = null
      this.render()
      return
    }

    this.selectedDate ||= this.localDate(new Date(), primary.timeZone)
    this.dateInputTarget.value = this.selectedDate
    const key = `${this.selectedDate}/${primary.timeZone}`
    if (this.loadedKey === key) {
      this.render()
      return
    }

    const request = new AbortController()
    this.request = request
    try {
      const url = new URL(this.urlValue, window.location.origin)
      url.search = new URLSearchParams({ date: this.selectedDate, time_zone: primary.timeZone })
      const response = await fetch(url, { signal: request.signal, headers: { Accept: "application/json" } })
      if (!response.ok) throw new Error("Timeline request failed")
      const data = await response.json()
      if (request.signal.aborted) return
      this.instants = data.instants.map((value) => new Date(value))
      this.loadedKey = key
      this.mobileHourOffset = 0
      this.statusTarget.textContent = this.instants.length ? "" : "There are no local times on this date in the selected timezone."
      this.render()
    } catch (error) {
      if (request.signal.aborted) return
      this.instants = []
      this.loadedKey = null
      this.mobileHourOffset = 0
      this.render()
      this.statusTarget.textContent = "Could not load this date. Please try again."
      this.retryTarget.hidden = false
    }
  }

  changeDate() {
    if (!this.dateInputTarget.value || !this.dateInputTarget.validity.valid) return
    this.selectedDate = this.dateInputTarget.value
    this.refresh()
  }

  previousWeek() { this.moveDay(-7) }
  previousDay() { this.moveDay(-1) }
  nextDay() { this.moveDay(1) }
  nextWeek() { this.moveDay(7) }

  moveDay(amount) {
    const date = new Date(`${this.selectedDate}T00:00:00Z`)
    date.setUTCDate(date.getUTCDate() + amount)
    this.selectedDate = date.toISOString().split("T")[0]
    this.refresh()
  }

  localDate(instant, timeZone) {
    const parts = new Intl.DateTimeFormat("en-US", {
      timeZone, year: "numeric", month: "2-digit", day: "2-digit"
    }).formatToParts(instant)
    const values = Object.fromEntries(parts.map(({ type, value }) => [type, value]))
    return `${values.year}-${values.month}-${values.day}`
  }

  render() {
    this.gridTarget.replaceChildren()
    this.navigationTarget.hidden = true

    if (this.cities.length === 0) {
      const empty = document.createElement("p")
      empty.className = "py-8 text-center text-slate-500"
      empty.textContent = "Choose your city to see the World Clock."
      this.gridTarget.append(empty)
      return
    }

    const mobile = window.matchMedia("(max-width: 639px)").matches
    const visibleInstants = mobile ? this.instants.slice(this.mobileHourOffset, this.mobileHourOffset + 12) : this.instants
    const hours = Math.max(visibleInstants.length, 1)
    this.renderNavigation(mobile)
    const cityColumn = "9rem"
    const columns = `${cityColumn} repeat(${hours}, minmax(0, 1fr))`
    const table = document.createElement("div")
    table.className = "w-full"
    table.addEventListener("mouseover", (event) => {
      const cell = event.target.closest("[data-hour-index]")
      if (cell && table.contains(cell)) this.highlightColumn(table, cell.dataset.hourIndex)
    })
    table.addEventListener("mouseleave", () => this.clearColumnHighlight(table))

    this.cities.forEach((city) => {
      const row = document.createElement("div")
      row.dataset.timeGridTarget = "row"
      row.className = "grid gap-px border-b border-slate-100 bg-slate-100 text-sm last:border-b-0"
      row.style.gridTemplateColumns = columns
      const cityCell = this.cityHeader(city)
      cityCell.classList.add("sticky", "left-0", "z-[1]")
      row.append(cityCell)

      const labels = this.instants.map((instant) => `${this.localDate(instant, city.timeZone)} ${this.formatTime(instant, city.timeZone)}`)
      let previousDate
      visibleInstants.forEach((instant) => {
        const date = this.localDate(instant, city.timeZone)
        const time = this.formatTime(instant, city.timeZone, true)
        const startsNewDate = date !== previousDate
        const cell = startsNewDate
          ? this.cell(this.formatDate(instant, city.timeZone), `min-w-0 cursor-pointer ${this.timeCellBackground(instant, city.timeZone)} flex flex-col items-center justify-center px-0.5 py-3 text-center text-[0.65rem] text-slate-600`)
          : this.timeCell(instant, city.timeZone)
        cell.dataset.instant = instant.toISOString()
        cell.dataset.hourIndex = visibleInstants.indexOf(instant).toString()
        cell.dataset.action = "click->time-grid#selectInstant"
        cell.setAttribute("aria-label", `${city.name}, ${date}, ${this.formatTime(instant, city.timeZone)}, ${this.offsetLabel(instant, city.timeZone)}`)
        const label = `${date} ${this.formatTime(instant, city.timeZone)}`
        if (labels.filter((value) => value === label).length > 1) {
          cell.append(this.cell(this.offsetLabel(instant, city.timeZone), "block text-[0.55rem] text-slate-500"))
        }
        previousDate = date
        row.append(cell)
      })
      table.append(row)
    })

    const viewport = document.createElement("div")
    viewport.className = "max-w-full overflow-x-auto rounded-xl border border-slate-200 bg-slate-200"
    viewport.append(table)
    this.gridTarget.append(viewport)
  }

  highlightColumn(table, hourIndex) {
    if (this.hoveredTable === table && this.hoveredHourIndex === hourIndex) return
    this.clearColumnHighlight(table)
    table.querySelectorAll(`[data-hour-index="${hourIndex}"]`).forEach((cell) => {
      cell.classList.add("bg-blue-50")
      cell.style.backgroundColor = "var(--color-blue-50)"
    })
    this.hoveredTable = table
    this.hoveredHourIndex = hourIndex
  }

  clearColumnHighlight(table) {
    table.querySelectorAll("[data-hour-index]").forEach((cell) => {
      cell.classList.remove("bg-blue-50")
      cell.style.removeProperty("background-color")
    })
    if (this.hoveredTable === table) {
      this.hoveredTable = null
      this.hoveredHourIndex = null
    }
  }

  renderNavigation(mobile) {
    if (!this.hasNavigationTarget) return

    this.navigationTarget.replaceChildren()
    this.navigationTarget.hidden = !mobile || this.instants.length <= 12
    if (this.navigationTarget.hidden) return

    const previous = document.createElement("button")
    previous.disabled = this.mobileHourOffset === 0
    previous.type = "button"
    previous.className = "rounded-lg px-3 py-2 text-sm font-bold text-blue-700 hover:bg-blue-50"
    previous.setAttribute("aria-label", "Show previous 12 hours")
    previous.textContent = "← Previous 12 hours"
    previous.dataset.action = "click->time-grid#previousPage"

    const next = document.createElement("button")
    next.disabled = this.mobileHourOffset + 12 >= this.instants.length
    next.type = "button"
    next.className = "rounded-lg px-3 py-2 text-sm font-bold text-blue-700 hover:bg-blue-50"
    next.setAttribute("aria-label", "Show next 12 hours")
    next.textContent = "Next 12 hours →"
    next.dataset.action = "click->time-grid#nextPage"

    this.navigationTarget.append(previous, next)
  }

  previousPage() {
    this.mobileHourOffset = 0
    this.render()
  }

  nextPage() {
    this.mobileHourOffset = Math.min(Math.floor((this.instants.length - 1) / 12) * 12, this.mobileHourOffset + 12)
    this.render()
  }

  selectInstant(event) {
    window.dispatchEvent(new CustomEvent("world-clock:instant-selected", {
      detail: { instant: event.currentTarget.dataset.instant }
    }))
  }

  cityHeader(city) {
    const header = document.createElement("div")
    header.className = "min-h-16 bg-slate-50 px-3 py-3"

    const cityLine = document.createElement("div")
    cityLine.className = "flex items-start justify-between gap-2"
    const name = document.createElement("strong")
    name.className = "block text-slate-700"
    name.textContent = city.name

    const action = document.createElement("button")
    action.type = "button"
    action.className = "w-fit shrink-0 rounded-lg px-1 py-0.5 text-xs font-bold hover:bg-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
    action.classList.add(city.primary ? "text-blue-700" : "text-slate-400")
    if (city.primary) {
      action.dataset.action = "click->world-clock#openChange"
      action.setAttribute("aria-label", "Change your city")
      action.title = "Change your city"
      action.append(this.icon("pencil"))
    } else {
      action.dataset.cityKey = city.key
      action.dataset.action = "click->world-clock#removeCity"
      action.setAttribute("aria-label", `Remove ${city.name}`)
      action.title = `Remove ${city.name}`
      action.append(this.icon("trash"))
    }
    cityLine.append(name, action)
    header.append(cityLine)

    const current = document.createElement("span")
    current.className = "mt-1 block text-[0.65rem] font-normal leading-tight text-slate-500"
    current.textContent = this.formatCurrentTime(new Date(), city.timeZone)
    header.append(current)
    return header
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
    path.setAttribute("d", name === "pencil"
      ? "m16.862 3.487 3.651 3.651M18.5 2.75a2.121 2.121 0 0 1 3 3L7.5 19.75 3 21l1.25-4.5L18.5 2.75Z"
      : "m6 7.5 1 12h10l1-12M4.5 7.5h15M9.5 7.5V5h5v2.5M10 11v5M14 11v5")
    svg.append(path)
    return svg
  }

  offsetLabel(instant, timeZone) {
    return new Intl.DateTimeFormat("en-US", { timeZone, timeZoneName: "longOffset" })
      .formatToParts(instant).find((part) => part.type === "timeZoneName").value
  }

  formatCurrentTime(instant, timeZone) {
    const time = this.formatTime(instant, timeZone, false)
    const date = new Intl.DateTimeFormat("en-US", {
      timeZone,
      weekday: "short",
      month: "short",
      day: "numeric"
    }).format(instant)
    return `${time}, ${date}`
  }

  formatDate(instant, timeZone) {
    return new Intl.DateTimeFormat("en-US", {
      timeZone,
      month: "short",
      day: "numeric"
    }).format(instant)
  }

  formatTime(instant, timeZone, compact = false) {
    const { hour, minute, period } = this.formatTimeParts(instant, timeZone)
    return compact && minute === "00" ? `${hour} ${period}` : `${hour}:${minute} ${period}`
  }

  formatTimeParts(instant, timeZone) {
    const parts = new Intl.DateTimeFormat("en-US", {
      timeZone,
      hour: "numeric",
      minute: "2-digit",
      hour12: true
    }).formatToParts(instant)
    return {
      hour: parts.find((part) => part.type === "hour")?.value || "",
      minute: parts.find((part) => part.type === "minute")?.value || "00",
      period: parts.find((part) => part.type === "dayPeriod")?.value || ""
    }
  }

  timeCellBackground(instant, timeZone) {
    const hour = Number(new Intl.DateTimeFormat("en-US", {
      timeZone,
      hour: "numeric",
      hourCycle: "h23"
    }).format(instant))
    return hour < 6 ? "bg-slate-100" : "bg-white"
  }

  timeCell(instant, timeZone) {
    const cell = document.createElement("div")
    cell.className = `min-w-0 cursor-pointer ${this.timeCellBackground(instant, timeZone)} flex flex-col items-center justify-center px-0.5 py-3 text-center text-slate-600`
    const { hour, minute, period } = this.formatTimeParts(instant, timeZone)
    const number = document.createElement("span")
    number.dataset.timeGridHour = ""
    number.className = "block text-base font-bold leading-none"
    number.textContent = minute === "00" ? hour : `${hour}:${minute}`
    const dayPeriod = document.createElement("span")
    dayPeriod.dataset.timeGridPeriod = ""
    dayPeriod.className = "block text-[0.65rem] leading-none"
    dayPeriod.textContent = period
    cell.append(number, dayPeriod)
    return cell
  }

  cell(text, className) {
    const cell = document.createElement("div")
    cell.className = className
    cell.textContent = text
    return cell
  }
}
