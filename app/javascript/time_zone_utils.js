function canonicalTimeZone(timeZone) {
  if (!timeZone) return null

  try {
    return new Intl.DateTimeFormat("en-US", { timeZone }).resolvedOptions().timeZone
  } catch (_error) {
    return null
  }
}

export function findCatalogTimeZone(catalog, timeZone) {
  const canonical = canonicalTimeZone(timeZone)
  if (!canonical) return null

  return catalog.find((city) => canonicalTimeZone(city.timeZone) === canonical)?.timeZone || null
}
