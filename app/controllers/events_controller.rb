class EventsController < ApplicationController
  skip_forgery_protection only: :create

  def create
    result = Events::Create.new(
      name: event_params[:name],
      description: event_params[:description],
      time_zone: event_params[:time_zone],
      cities: event_params[:cities],
      instants: event_params[:instants]
    ).call

    cookies.signed[management_cookie_key(result.event)] = {
      value: result.management_token,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax
    }

    render json: { public_token: result.event.public_token }, status: :created
  rescue Events::Create::ValidationError => error
    render json: { errors: error.errors }, status: :unprocessable_content
  end

  private

  def event_params
    params.permit(:name, :description, :time_zone, instants: [], cities: [ :key, :name, :region, :time_zone, :is_primary, :primary ])
  end

  def management_cookie_key(event)
    "event_management_#{event.public_token}"
  end
end
