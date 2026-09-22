require "rails_helper"

RSpec.describe Events::Destroy do
  let(:cities) do
    [
      { key: "vancouver", name: "Vancouver", region: "Canada", time_zone: "America/Vancouver", is_primary: true },
      { key: "tokyo", name: "Tokyo", region: "Japan", time_zone: "Asia/Tokyo", is_primary: false }
    ]
  end
  let(:result) do
    Events::Create.new(
      name: "Planning session",
      description: "Choose a time",
      time_zone: "America/Vancouver",
      cities: cities,
      instants: [ 2.hours.from_now.iso8601 ]
    ).call
  end

  it "deletes the event and all related records with the management token" do
    event = result.event
    response = event.responses.create!(name: "Alex", time_zone: "America/Vancouver")
    event.time_options.first.votes.create!(response: response, availability: :available)

    expect {
      described_class.new(event: event, management_token: result.management_token).call
    }.to change(Event, :count).by(-1)
      .and change(EventCity, :count).by(-2)
      .and change(TimeOption, :count).by(-1)
      .and change(Response, :count).by(-1)
      .and change(Vote, :count).by(-1)
  end

  it "rejects an invalid management token without deleting the event" do
    event = result.event

    expect {
      described_class.new(event: event, management_token: "wrong-token").call
    }.to raise_error(described_class::AuthorizationError)

    expect(event).to be_persisted
  end
end
