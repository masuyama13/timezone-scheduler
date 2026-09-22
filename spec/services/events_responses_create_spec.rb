require "rails_helper"

RSpec.describe Events::Responses::Create do
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
  let(:choices) do
    event.time_options.order(:starts_at).map.with_index do |time_option, index|
      { time_option_id: time_option.id, availability: index.zero? ? "available" : "maybe" }
    end
  end

  it "creates a response and all of its votes atomically" do
    response = described_class.new(
      event: event,
      name: "Alex",
      time_zone: "America/Vancouver",
      comment: "Looking forward to it",
      choices: choices
    ).call

    expect(response).to be_persisted
    expect(response.votes.pluck(:availability)).to contain_exactly("available", "maybe")
    expect(response.comment).to eq("Looking forward to it")
  end

  it "rejects a response when a time option is unanswered" do
    expect {
      described_class.new(
        event: event,
        name: "Alex",
        time_zone: "America/Vancouver",
        comment: "",
        choices: choices.first(1)
      ).call
    }.to raise_error(described_class::ValidationError, /Answer every time option/)

    expect(Response.count).to eq(0)
  end

  it "rejects invalid response fields" do
    expect {
      described_class.new(
        event: event,
        name: "A" * 51,
        time_zone: "Invalid/Zone",
        comment: "A" * 401,
        choices: choices
      ).call
    }.to raise_error(described_class::ValidationError) { |error|
      expect(error.errors).to include("Name must be 50 characters or fewer.")
      expect(error.errors).to include("Comment must be 400 characters or fewer.")
      expect(error.errors).to include("Choose a valid time zone.")
    }
  end

  it "rejects a twenty-first response" do
    20.times do |index|
      event.responses.create!(name: "Guest #{index}", time_zone: "America/Vancouver")
    end

    expect {
      described_class.new(
        event: event,
        name: "Alex",
        time_zone: "America/Vancouver",
        comment: "",
        choices: choices
      ).call
    }.to raise_error(described_class::ValidationError, /already has 20 responses/)
  end
end
