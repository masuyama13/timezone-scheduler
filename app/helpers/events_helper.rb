module EventsHelper
  CITY_NAMES_BY_TIME_ZONE = {
    "America/Vancouver" => "Vancouver",
    "America/Toronto" => "Toronto",
    "America/New_York" => "New York",
    "America/Chicago" => "Chicago",
    "America/Denver" => "Denver",
    "America/Los_Angeles" => "Los Angeles",
    "Pacific/Honolulu" => "Honolulu",
    "America/Mexico_City" => "Mexico City",
    "America/Sao_Paulo" => "São Paulo",
    "Europe/London" => "London",
    "Europe/Paris" => "Paris",
    "Europe/Berlin" => "Berlin",
    "Asia/Dubai" => "Dubai",
    "Asia/Kolkata" => "Delhi",
    "Asia/Singapore" => "Singapore",
    "Asia/Hong_Kong" => "Hong Kong",
    "Asia/Tokyo" => "Tokyo",
    "Asia/Seoul" => "Seoul",
    "Australia/Sydney" => "Sydney",
    "Pacific/Auckland" => "Auckland"
  }.freeze

  def city_name_for_time_zone(time_zone)
    CITY_NAMES_BY_TIME_ZONE.fetch(time_zone, time_zone)
  end

  AVAILABILITY_OPTIONS = [
    [ "available", "Available", "✓" ],
    [ "maybe", "Maybe", "?" ],
    [ "unavailable", "Not available", "×" ]
  ].freeze

  def availability_label(value)
    AVAILABILITY_OPTIONS.find { |key, _label, _symbol| key == value }&.second || "Unknown"
  end

  def availability_symbol(value)
    AVAILABILITY_OPTIONS.find { |key, _label, _symbol| key == value }&.third || "?"
  end

  def availability_counts(time_option, responses)
    counts = responses.flat_map { |response| response.votes.select { |vote| vote.time_option_id == time_option.id }.map(&:availability) }.tally
    AVAILABILITY_OPTIONS.to_h { |key, label, _symbol| [ label, counts.fetch(key, 0) ] }
  end
end
