require "digest"
require "active_support/security_utils"

module Events
  class Destroy
    class AuthorizationError < StandardError; end

    def self.authorized?(event, management_token)
      return false if management_token.blank? || event.management_token_digest.blank?

      digest = Digest::SHA256.hexdigest(management_token)
      ActiveSupport::SecurityUtils.secure_compare(digest, event.management_token_digest)
    end

    def initialize(event:, management_token:)
      @event = event
      @management_token = management_token
    end

    def call
      raise AuthorizationError unless self.class.authorized?(@event, @management_token)

      @event.destroy!
    end
  end
end
