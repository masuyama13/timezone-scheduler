module Events
  class ResponsesController < ApplicationController
    skip_forgery_protection only: [ :create, :update, :destroy ]

    def update
      event = find_event
      return render_not_found unless event

      response_id = request.path_parameters.fetch(:response_id)
      response = event.responses.where(id: response_id).first
      return render_not_found unless response

      submitted_params = response_params
      choices = submitted_params[:choices]
      choices = choices.values if choices.is_a?(Hash)

      updated_response = Events::Responses::Update.new(
        event: event,
        response: response,
        name: submitted_params[:name],
        time_zone: submitted_params[:time_zone],
        comment: submitted_params[:comment],
        choices: choices || []
      ).call

      render json: { response_id: updated_response.id }, status: :ok
    rescue Events::Responses::Update::ValidationError => error
      render json: { errors: error.errors }, status: :unprocessable_content
    end

    def destroy
      event = find_event
      return render_not_found unless event

      response_id = request.path_parameters.fetch(:response_id)
      response = event.responses.where(id: response_id).first
      return render_not_found unless response

      Events::Responses::Destroy.new(event: event, response: response).call
      head :no_content
    end

    def create
      event = find_event
      return render_not_found unless event

      submitted_params = response_params
      choices = submitted_params[:choices]
      choices = choices.values if choices.is_a?(Hash)

      response = Events::Responses::Create.new(
        event: event,
        name: submitted_params[:name],
        time_zone: submitted_params[:time_zone],
        comment: submitted_params[:comment],
        choices: choices || []
      ).call

      render json: { response_id: response.id }, status: :created
    rescue Events::Responses::Create::ValidationError => error
      render json: { errors: error.errors }, status: :unprocessable_content
    end

    private

    def find_event
      public_token = request.path_parameters.fetch(:public_token)
      ::Event.find_by(public_token: public_token)
    end

    def response_params
      raw_params = if request.media_type == "application/json"
        JSON.parse(request.raw_post)
      else
        Rack::Utils.parse_nested_query(request.raw_post)
      end

      {
        name: raw_params["name"],
        time_zone: raw_params["time_zone"],
        comment: raw_params["comment"],
        choices: raw_params["choices"]
      }
    rescue JSON::ParserError
      {}
    end
  end
end
