module WorldClock
  class LocalTimeResolver
    attr_reader :date, :time_zone

    def initialize(date:, time_zone:)
      @date = parse_date(date)
      @time_zone = TZInfo::Timezone.get(time_zone)
    end

    # Empty means nonexistent; multiple results require an explicit user choice.
    # Never let TZInfo's default DST preference silently choose an occurrence.
    def call(hour:, minute: 0)
      unless hour.is_a?(Integer) && (0..23).cover?(hour) &&
          minute.is_a?(Integer) && (0..59).cover?(minute)
        raise ArgumentError, "Hour and minute must be integers in 0..23 and 0..59"
      end

      local = Time.utc(date.year, date.month, date.day, hour, minute)
      time_zone.periods_for_local(local).map do |period|
        (local - period.observed_utc_offset).utc
      end.uniq.sort
    end

    private

    def parse_date(value)
      return value if value.instance_of?(Date)

      unless value.is_a?(String) && /\A\d{4,}-\d{2}-\d{2}\z/.match?(value)
        raise ArgumentError, "Date must be a Date or an ISO calendar date"
      end

      Date.iso8601(value)
    end
  end
end
