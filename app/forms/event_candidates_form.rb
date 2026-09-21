class EventCandidatesForm
  include ActiveModel::Model

  MINIMUM = 1
  MAXIMUM = 10

  attr_accessor :instants

  validates :instants, presence: true
  validate :validate_count
  validate :validate_timestamps

  def normalized_instants
    @normalized_instants ||= Array(instants).map { |value| Time.iso8601(value.to_s).utc }
  rescue ArgumentError, TypeError
    []
  end

  private

  def validate_count
    count = Array(instants).length
    errors.add(:instants, "must include between #{MINIMUM} and #{MAXIMUM} times") unless (MINIMUM..MAXIMUM).cover?(count)
  end

  def validate_timestamps
    parsed = normalized_instants
    return errors.add(:instants, "must contain valid UTC timestamps") unless parsed.length == Array(instants).length
    return errors.add(:instants, "must not contain duplicate times") unless parsed.uniq.length == parsed.length

    errors.add(:base, "Select times in the future.") unless parsed.all? { |instant| instant > Time.current }
  end
end
