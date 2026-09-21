require "rails_helper"

RSpec.describe EventCandidatesForm do
  let(:future_times) { [ 2.hours.from_now.iso8601, 3.hours.from_now.iso8601 ] }

  it "accepts one to ten distinct future instants" do
    form = described_class.new(instants: future_times)

    expect(form).to be_valid
    expect(form.normalized_instants).to all(be_a(Time))
  end

  it "rejects no instants or more than ten instants" do
    expect(described_class.new(instants: [])).not_to be_valid
    expect(described_class.new(instants: Array.new(11) { |index| (index + 2).hours.from_now.iso8601 })).not_to be_valid
  end

  it "rejects duplicate, invalid, and non-future instants" do
    expect(described_class.new(instants: [ future_times.first, future_times.first ])).not_to be_valid
    expect(described_class.new(instants: [ "invalid", future_times.last ])).not_to be_valid
    expect(described_class.new(instants: [ 1.hour.ago.iso8601, future_times.last ])).not_to be_valid
  end
end
