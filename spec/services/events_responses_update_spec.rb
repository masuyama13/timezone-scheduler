require "rails_helper"

RSpec.describe Events::Responses::Update do
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
  let!(:response) { event.responses.create!(name: "Alex", time_zone: "America/Vancouver", comment: "Original") }
  let(:choices) do
    event.time_options.order(:starts_at).map.with_index do |time_option, index|
      { time_option_id: time_option.id, availability: index.zero? ? "available" : "maybe" }
    end
  end

  before do
    response.votes.create!(time_option: event.time_options.first, availability: :unavailable)
    response.votes.create!(time_option: event.time_options.second, availability: :unavailable)
  end

  it "updates the response and replaces all votes" do
    updated = described_class.new(
      event: event,
      response: response,
      name: "Jordan",
      time_zone: "Asia/Tokyo",
      comment: "Updated comment",
      choices: choices
    ).call

    expect(updated.reload).to have_attributes(name: "Jordan", time_zone: "Asia/Tokyo", comment: "Updated comment")
    expect(updated.votes.order(:time_option_id).pluck(:availability)).to eq(%w[available maybe])
  end

  it "rejects incomplete choices without changing the response" do
    expect {
      described_class.new(
        event: event,
        response: response,
        name: "Jordan",
        time_zone: "Asia/Tokyo",
        comment: "Updated comment",
        choices: choices.first(1)
      ).call
    }.to raise_error(described_class::ValidationError, /Answer every time option/)

    expect(response.reload.name).to eq("Alex")
    expect(response.votes.pluck(:availability)).to all(eq("unavailable"))
  end
end
