require "rails_helper"

RSpec.describe EventCity, type: :model do
  it "belongs to an event" do
    association = described_class.reflect_on_association(:event)

    expect(association.macro).to eq(:belongs_to)
  end

  it "requires a complete city snapshot" do
    event_city = described_class.new

    expect(event_city).not_to be_valid
    expect(event_city.errors.attribute_names).to include(:city_key, :name, :region, :time_zone)
  end
end
