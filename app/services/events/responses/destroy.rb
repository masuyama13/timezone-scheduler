module Events
  module Responses
    class Destroy
      def initialize(event:, response:)
        @event = event
        @response = response
      end

      def call
        @event.with_lock do
          @response.destroy!
        end
      end
    end
  end
end
