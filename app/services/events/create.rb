require "digest"
require "securerandom"

module Events
  class Create
    MINIMUM_CITIES = 1
    MAXIMUM_CITIES = 10

    class ValidationError < StandardError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
        super(errors.join(" "))
      end
    end

    Result = Data.define(:event, :management_token)

    def initialize(name:, description:, time_zone:, cities:, instants:)
      @name = name.to_s.strip
      @description = description.to_s.strip
      @time_zone = time_zone.to_s
      @cities = normalize_cities(cities)
      @instants = instants
    end

    def call
      validate_input!

      management_token = SecureRandom.urlsafe_base64(32)
      event = Event.new(
        name: @name,
        description: @description.presence,
        time_zone: @time_zone,
        public_token: generate_public_token,
        management_token_digest: digest(management_token)
      )

      Event.transaction do
        event.save!
        @cities.each { |city| event.event_cities.create!(city) }
        EventCandidatesForm.new(instants: @instants).normalized_instants.each do |instant|
          event.time_options.create!(starts_at: instant)
        end
      end

      Result.new(event, management_token)
    rescue ActiveRecord::RecordInvalid => error
      raise ValidationError, [ error.record.errors.full_messages.to_sentence ]
    end

    private

    def validate_input!
      errors = []
      errors << "Title is required." if @name.blank?
      errors << "Title must be 100 characters or fewer." if @name.length > 100
      errors << "Description must be 400 characters or fewer." if @description.length > 400
      errors << "Choose a valid primary time zone." unless valid_time_zone?

      if @cities.length < MINIMUM_CITIES || @cities.length > MAXIMUM_CITIES
        errors << "Choose between #{MINIMUM_CITIES} and #{MAXIMUM_CITIES} cities."
      end
      errors << "Choose exactly one primary city." unless @cities.count { |city| city[:is_primary] } == 1

      candidate_form = EventCandidatesForm.new(instants: @instants)
      errors.concat(candidate_form.errors.full_messages) unless candidate_form.valid?
      raise ValidationError, errors if errors.any?
    end

    def normalize_cities(cities)
      Array(cities).map do |city|
        attributes = city.respond_to?(:to_h) ? city.to_h.symbolize_keys : {}
        {
          city_key: attributes[:key].to_s,
          name: attributes[:name].to_s,
          region: attributes[:region].to_s,
          time_zone: attributes[:time_zone].to_s,
          is_primary: ActiveModel::Type::Boolean.new.cast(
            attributes.key?(:is_primary) ? attributes[:is_primary] : attributes[:primary]
          )
        }
      end
    end

    def valid_time_zone?
      TZInfo::Timezone.get(@time_zone)
      true
    rescue TZInfo::InvalidTimezoneIdentifier
      false
    end

    def generate_public_token
      loop do
        token = SecureRandom.urlsafe_base64(32)
        break token unless Event.exists?(public_token: token)
      end
    end

    def digest(token)
      Digest::SHA256.hexdigest(token)
    end
  end
end
