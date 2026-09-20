module WorldClock
  class DayTimeline
    def initialize(date:, time_zone:)
      @resolver = LocalTimeResolver.new(date: date, time_zone: time_zone)
    end

    # UTC instants shared by every city column. A skipped local date returns [].
    def call
      hours = (0..23).flat_map { |hour| @resolver.call(hour: hour) }
      (hours + transition_instants).uniq.sort
    end

    private

    def transition_instants
      date = @resolver.date
      midnight = Time.utc(date.year, date.month, date.day)
      # Include transitions around the whole local day regardless of UTC offset.
      transitions = @resolver.time_zone.transitions_up_to(midnight + 3.days, midnight - 3.days)
      transitions.filter_map do |transition|
        instant = transition.at.to_time.utc
        # Include partial hours (e.g. Lord Howe's 02:30 after a 30-minute jump).
        instant if @resolver.time_zone.to_local(instant).to_date == date
      end
    end
  end
end
