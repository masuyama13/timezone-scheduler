module WorldClock
  class TimeResolutionsController < ApplicationController
    def show
      unless params[:date].is_a?(String) && params[:time].is_a?(String) && params[:time_zone].is_a?(String)
        return invalid_request
      end

      hour, minute = params[:time].split(":", 2).map(&:to_i)
      instants = LocalTimeResolver.new(date: params[:date], time_zone: params[:time_zone]).call(hour:, minute:)
      render json: { instants: instants.map(&:iso8601) }
    rescue ArgumentError, TZInfo::InvalidTimezoneIdentifier, RangeError
      invalid_request
    end

    private

    def invalid_request
      render json: { error: "Choose a valid local date, time, and timezone." }, status: :unprocessable_content
    end
  end
end
