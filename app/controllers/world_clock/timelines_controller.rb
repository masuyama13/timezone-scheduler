module WorldClock
  class TimelinesController < ApplicationController
    def show
      unless params[:date].is_a?(String) && params[:time_zone].is_a?(String)
        return render json: { error: "Choose a valid date and timezone." }, status: :unprocessable_content
      end

      instants = DayTimeline.new(date: params[:date], time_zone: params[:time_zone]).call
      render json: { instants: instants.map(&:iso8601) }
    rescue ArgumentError, TZInfo::InvalidTimezoneIdentifier, RangeError
      render json: { error: "Choose a valid date and timezone." }, status: :unprocessable_content
    end
  end
end
