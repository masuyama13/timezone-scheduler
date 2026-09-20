import { Controller } from "@hotwired/stimulus"
import { CITY_CATALOG } from "city_catalog"

const STORAGE_KEY = "timezone-scheduler.world-clock"

export default class extends Controller {
  static targets = ["grid", "navigation"]

  connect() {
    this.mobileHourOffset = 0
    this.cities = this.loadCities()
    this.boundCitiesChanged = (event) => {
      this.cities = event.detail || this.loadCities()
      this.render()
    }
    window.addEventListener("world-clock:cities-changed", this.boundCitiesChanged)
    this.boundResize = () => this.render()
    window.addEventListener("resize", this.boundResize)
    this.render()
  }

  disconnect() {
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

  render() {
    this.gridTarget.replaceChildren()

    if (this.cities.length === 0) {
      const empty = document.createElement("p")
      empty.className = "py-8 text-center text-slate-500"
      empty.textContent = "Choose your city to see the World Clock."
      this.gridTarget.append(empty)
      return
    }

    const primaryCity = this.cities.find((city) => city.primary) || this.cities[0]
    const mobile = window.matchMedia("(max-width: 639px)").matches
    const hours = mobile ? 12 : 24
    const start = new Date(this.currentHour().getTime() + (mobile ? this.mobileHourOffset : 0) * 60 * 60 * 1000)
    this.renderNavigation(mobile)
    const cityColumn = "9rem"
    const columns = `${cityColumn} repeat(${hours}, minmax(0, 1fr))`
    const table = document.createElement("div")
    table.className = "w-full"

    this.cities.forEach((city) => {
      const row = document.createElement("div")
      row.dataset.timeGridTarget = "row"
      row.className = "grid gap-px border-b border-slate-100 bg-slate-100 text-sm last:border-b-0"
      row.style.gridTemplateColumns = columns
      const cityCell = this.cityHeader(city)
      cityCell.classList.add("sticky", "left-0", "z-[1]")
      row.append(cityCell)

      for (let hour = 0; hour < hours; hour += 1) {
        const instant = new Date(start.getTime() + hour * 60 * 60 * 1000)
        row.append(this.cell(this.formatTime(instant, city.timeZone, true), "bg-white px-1 py-4 text-center text-xs text-slate-600"))
      }
      table.append(row)
    })

    const viewport = document.createElement("div")
    viewport.className = "max-w-full overflow-x-auto rounded-xl border border-slate-200 bg-slate-200"
    viewport.append(table)
    this.gridTarget.append(viewport)
  }

  renderNavigation(mobile) {
    if (!this.hasNavigationTarget) return

    this.navigationTarget.replaceChildren()
    this.navigationTarget.hidden = !mobile
    if (!mobile) return

    const previous = document.createElement("button")
    previous.type = "button"
    previous.className = "rounded-lg px-3 py-2 text-sm font-bold text-blue-700 hover:bg-blue-50"
    previous.setAttribute("aria-label", "Show previous 12 hours")
    previous.textContent = "← Previous 12 hours"
    previous.dataset.action = "click->time-grid#previousPage"

    const next = document.createElement("button")
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
    this.mobileHourOffset = 12
    this.render()
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

  currentHour() {
    const primaryCity = this.cities.find((city) => city.primary) || this.cities[0]
    const parts = new Intl.DateTimeFormat("en-US", {
      timeZone: primaryCity.timeZone,
      year: "numeric",
      month: "2-digit",
      day: "2-digit"
    }).formatToParts(new Date())
    const values = Object.fromEntries(parts.filter((part) => part.type !== "literal").map((part) => [part.type, Number(part.value)]))
    const localMidnight = Date.UTC(values.year, values.month - 1, values.day)
    const offsetParts = new Intl.DateTimeFormat("en-US", {
      timeZone: primaryCity.timeZone,
      timeZoneName: "longOffset",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
      hourCycle: "h23"
    }).formatToParts(new Date(localMidnight))
    const offset = offsetParts.find((part) => part.type === "timeZoneName")?.value || "GMT"
    const match = offset.match(/GMT([+-])(\d{2}):(\d{2})/)
    const offsetMinutes = match ? (Number(match[2]) * 60 + Number(match[3])) * (match[1] === "+" ? 1 : -1) : 0
    return new Date(localMidnight - offsetMinutes * 60 * 1000)
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
    const parts = new Intl.DateTimeFormat("en-US", {
      timeZone,
      hour: "numeric",
      minute: compact ? undefined : "2-digit",
      hour12: true
    }).formatToParts(instant)
    const hour = parts.find((part) => part.type === "hour")?.value || ""
    const minute = parts.find((part) => part.type === "minute")?.value || "00"
    const period = parts.find((part) => part.type === "dayPeriod")?.value || ""
    return compact ? `${hour} ${period}` : `${hour}:${minute} ${period}`
  }

  cell(text, className) {
    const cell = document.createElement("div")
    cell.className = className
    cell.textContent = text
    return cell
  }
}
