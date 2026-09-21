class EventsController < ApplicationController
  skip_forgery_protection only: [ :create, :destroy ]

  def create
    result = Events::Create.new(
      name: event_params[:name],
      description: event_params[:description],
      time_zone: event_params[:time_zone],
      cities: event_params[:cities],
      instants: event_params[:instants]
    ).call

    cookies[management_cookie_key(result.event)] = {
      value: result.management_token,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax
    }

    render json: { public_token: result.event.public_token }, status: :created
  rescue Events::Create::ValidationError => error
    render json: { errors: error.errors }, status: :unprocessable_content
  end

  def show
    @event = Event.includes(:event_cities, :time_options).find_by(public_token: params[:public_token])
    render_not_found unless @event
  end

  def destroy
    event = Event.find_by(public_token: params[:public_token])
    return render_not_found unless event

    Events::Destroy.new(
      event: event,
      management_token: cookies[management_cookie_key(event)]
    ).call
    cookies.delete(management_cookie_key(event))
    redirect_to root_path, status: :see_other
  rescue Events::Destroy::AuthorizationError
    head :forbidden
  end

  private

  def event_params
    params.permit(:name, :description, :time_zone, instants: [], cities: [ :key, :name, :region, :time_zone, :is_primary, :primary ])
  end

  helper_method :management_authorized?

  def management_authorized?(event)
    Events::Destroy.authorized?(event, cookies[management_cookie_key(event)])
  end

  def management_cookie_key(event)
    "event_management_#{event.public_token}"
  end
end
