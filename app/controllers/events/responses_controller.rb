module Events
  class ResponsesController < ApplicationController
    skip_forgery_protection only: :create

    def create
      event = Event.find_by(public_token: params[:public_token])
      return render_not_found unless event

      response = Events::Responses::Create.new(
        event: event,
        name: response_params[:name],
        time_zone: response_params[:time_zone],
        comment: response_params[:comment],
        choices: response_params[:choices].presence&.to_h&.values || []
      ).call

      render json: { response_id: response.id }, status: :created
    rescue Events::Responses::Create::ValidationError => error
      render json: { errors: error.errors }, status: :unprocessable_content
    end

    private

    def response_params
      params.permit(:name, :time_zone, :comment, choices: [ :time_option_id, :availability ])
    end
  end
end
