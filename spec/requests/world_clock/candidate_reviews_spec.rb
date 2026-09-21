require "rails_helper"

RSpec.describe "World Clock candidate reviews", type: :request do
  let(:future_times) { [ 2.hours.from_now.iso8601, 3.hours.from_now.iso8601 ] }

  it "validates a single candidate instant without creating an Event" do
    expect {
      post world_clock_candidate_review_path, params: { instants: [ future_times.first ] }
    }.not_to change(Event, :count)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("instants").length).to eq(1)
  end

  it "returns validation errors for invalid candidates" do
    post world_clock_candidate_review_path, params: { instants: [ 1.hour.ago.iso8601 ] }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("errors")).to include("Select times in the future.")
  end
end
