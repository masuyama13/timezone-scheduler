module Events
  module Responses
    class Create
      MAXIMUM_RESPONSES = 20
      MAXIMUM_NAME_LENGTH = 50
      MAXIMUM_COMMENT_LENGTH = 400

      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(" "))
        end
      end

      def initialize(event:, name:, time_zone:, comment:, choices:)
        @event = event
        @name = name.to_s.strip
        @time_zone = time_zone.to_s
        @comment = comment.to_s.strip
        @choices = normalize_choices(choices)
      end

      def call
        validate_input!

        @event.with_lock do
          if @event.responses.count >= MAXIMUM_RESPONSES
            raise ValidationError, [ "This event already has #{MAXIMUM_RESPONSES} responses." ]
          end

          response = @event.responses.create!(
            name: @name,
            time_zone: @time_zone,
            comment: @comment.presence
          )
          @choices.each do |choice|
            response.votes.create!(
              time_option_id: choice[:time_option_id],
              availability: choice[:availability]
            )
          end
          response
        end
      rescue ActiveRecord::RecordInvalid => error
        raise ValidationError, [ error.record.errors.full_messages.to_sentence ]
      end

      private

      def validate_input!
        errors = []
        errors << "Name is required." if @name.blank?
        errors << "Name must be #{MAXIMUM_NAME_LENGTH} characters or fewer." if @name.length > MAXIMUM_NAME_LENGTH
        errors << "Comment must be #{MAXIMUM_COMMENT_LENGTH} characters or fewer." if @comment.length > MAXIMUM_COMMENT_LENGTH
        errors << "Choose a valid time zone." unless valid_time_zone?

        time_option_ids = @event.time_options.pluck(:id)
        choice_ids = @choices.map { |choice| choice[:time_option_id] }
        errors << "Answer every time option." unless choice_ids.uniq.sort == time_option_ids.sort
        errors << "Choose a valid availability for every time option." unless valid_availabilities?
        errors << "Each time option can only be answered once." unless choice_ids.length == choice_ids.uniq.length
        raise ValidationError, errors if errors.any?
      end

      def normalize_choices(choices)
        Array(choices).filter_map do |choice|
          attributes = choice.respond_to?(:to_h) ? choice.to_h.symbolize_keys : {}
          {
            time_option_id: attributes[:time_option_id].to_i,
            availability: attributes[:availability].to_s
          }
        end
      end

      def valid_availabilities?
        @choices.all? { |choice| Vote.availabilities.key?(choice[:availability]) }
      end

      def valid_time_zone?
        TZInfo::Timezone.get(@time_zone)
        true
      rescue TZInfo::InvalidTimezoneIdentifier
        false
      end
    end
  end
end
