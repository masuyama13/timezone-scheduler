require "rails_helper"

RSpec.describe "Events", type: :request do
  let(:params) do
    {
      name: "Planning session",
      description: "Choose a time",
      time_zone: "America/Vancouver",
      cities: [
        { key: "vancouver", name: "Vancouver", region: "Canada", time_zone: "America/Vancouver", is_primary: "true" },
        { key: "tokyo", name: "Tokyo", region: "Japan", time_zone: "Asia/Tokyo", is_primary: "false" }
      ],
      instants: [ 2.hours.from_now.iso8601, 3.hours.from_now.iso8601 ]
    }
  end

  it "creates an event and sets a management cookie" do
    expect {
      post events_path, params: params
    }.to change(Event, :count).by(1).and change(EventCity, :count).by(2).and change(TimeOption, :count).by(2)

    expect(response).to have_http_status(:created)
    expect(response.parsed_body.fetch("public_token")).to eq(Event.last.public_token)
    expect(response.cookies.keys).to include("event_management_#{Event.last.public_token}")
  end

  it "returns validation errors without persisting an event" do
    expect {
      post events_path, params: params.merge(name: "")
    }.not_to change(Event, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("errors")).to include("Title is required.")
  end

  describe "GET /events/:public_token" do
    it "renders the saved event and share link" do
      post events_path, params: params
      event = Event.last

      get event_path(event.public_token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Planning session")
      expect(response.body).to include("Choose a time")
      expect(response.body).to include(event_path(event.public_token))
      expect(response.body).to include("This page and its responses may be deleted after one year.")
    end

    it "returns not found for an unknown public token" do
      get event_path("missing-event")

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Page not found")
      expect(response.body).to include("Back to home")
    end

    it "deletes an event with the management cookie" do
      post events_path, params: params
      event = Event.last

      expect {
        delete event_path(event.public_token)
      }.to change(Event, :count).by(-1)

      expect(response).to have_http_status(:see_other)
      get event_path(event.public_token)
      expect(response).to have_http_status(:not_found)
    end

    it "rejects deletion without the management cookie" do
      post events_path, params: params
      event = Event.last
      cookies.delete("event_management_#{event.public_token}")

      delete event_path(event.public_token)

      expect(response).to have_http_status(:forbidden)
      expect(Event.exists?(event.id)).to be(true)
    end

    it "returns not found when deleting an unknown event" do
      delete event_path("missing-event")

      expect(response).to have_http_status(:not_found)
    end

    it "accepts a response with availability choices" do
      post events_path, params: params
      event = Event.last
      choices = event.time_options.order(:starts_at).each_with_index.to_h do |time_option, index|
        [ index.to_s, { time_option_id: time_option.id, availability: index.zero? ? "available" : "maybe" } ]
      end

      expect {
        post event_responses_path(event.public_token), params: {
          name: "Alex",
          time_zone: "America/Vancouver",
          comment: "Looking forward to it",
          choices: choices
        }, as: :json
      }.to change(Response, :count).by(1).and change(Vote, :count).by(2)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.fetch("response_id")).to eq(Response.last.id)
      expect(Response.last.votes.pluck(:availability)).to contain_exactly("available", "maybe")
    end

    it "rejects a response with an unanswered time option" do
      post events_path, params: params
      event = Event.last
      time_option = event.time_options.first

      post event_responses_path(event.public_token), params: {
        name: "Alex",
        time_zone: "America/Vancouver",
        choices: { "0" => { time_option_id: time_option.id, availability: "available" } }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include("Answer every time option.")
    end
  end
end
