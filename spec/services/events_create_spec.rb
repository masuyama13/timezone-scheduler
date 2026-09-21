require "rails_helper"

RSpec.describe Events::Create do
  let(:cities) do
    [
      { key: "vancouver", name: "Vancouver", region: "Canada", time_zone: "America/Vancouver", is_primary: true },
      { key: "tokyo", name: "Tokyo", region: "Japan", time_zone: "Asia/Tokyo", is_primary: false }
    ]
  end
  let(:instants) { [ 2.hours.from_now.iso8601, 3.hours.from_now.iso8601 ] }

  it "creates an event, city snapshots, and time options atomically" do
    result = described_class.new(
      name: "Planning session",
      description: "Choose a time",
      time_zone: "America/Vancouver",
      cities: cities,
      instants: instants
    ).call

    expect(result.event).to be_persisted
    expect(result.event.event_cities.pluck(:city_key)).to contain_exactly("vancouver", "tokyo")
    expect(result.event.time_options.count).to eq(2)
    expect(result.management_token).to be_present
    expect(result.event.management_token_digest).to eq(Digest::SHA256.hexdigest(result.management_token))
  end

  it "rejects invalid input without persisting an incomplete event" do
    expect {
      described_class.new(
        name: "",
        description: "",
        time_zone: "America/Vancouver",
        cities: cities,
        instants: instants
      ).call
    }.to raise_error(Events::Create::ValidationError, /Title is required/)

    expect(Event.count).to eq(0)
  end
end
