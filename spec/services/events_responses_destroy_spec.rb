require "rails_helper"

RSpec.describe Events::Responses::Destroy do
  let!(:event) do
    Events::Create.new(
      name: "Planning session",
      description: "Choose a time",
      time_zone: "America/Vancouver",
      cities: [
        { key: "vancouver", name: "Vancouver", region: "Canada", time_zone: "America/Vancouver", is_primary: true }
      ],
      instants: [ 2.hours.from_now.iso8601, 3.hours.from_now.iso8601 ]
    ).call.event
  end
  let!(:response) { event.responses.create!(name: "Alex", time_zone: "America/Vancouver") }

  before do
    event.time_options.each do |time_option|
      response.votes.create!(time_option: time_option, availability: :available)
    end
  end

  it "deletes the response and its votes" do
    expect {
      described_class.new(event: event, response: response).call
    }.to change(Response, :count).by(-1).and change(Vote, :count).by(-2)

    expect(event.reload).to be_persisted
    expect(event.time_options.count).to eq(2)
  end
end
