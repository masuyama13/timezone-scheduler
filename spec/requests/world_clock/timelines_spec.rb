require "rails_helper"

RSpec.describe "World Clock timelines", type: :request do
  it "returns a local day as UTC instants" do
    get world_clock_timeline_path, params: { date: "2026-09-20", time_zone: "Asia/Tokyo" }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("instants")).to eq(
      Array.new(24) { |hour| (Time.utc(2026, 9, 19, 15) + hour.hours).iso8601 }
    )
  end

  it "returns all 25 instants on a fall transition" do
    get world_clock_timeline_path, params: { date: "2026-11-01", time_zone: "America/New_York" }
    expect(response.parsed_body.fetch("instants").length).to eq(25)
  end

  it "returns an empty list for a skipped date" do
    get world_clock_timeline_path, params: { date: "2011-12-30", time_zone: "Pacific/Apia" }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("instants")).to eq([])
  end

  it "rejects invalid and missing parameters" do
    [ {}, { date: "2026-02-30", time_zone: "Asia/Tokyo" },
      { date: "2026-09-20", time_zone: "Invalid/Zone" },
      { date: [ "2026-09-20" ], time_zone: "Asia/Tokyo" },
      { date: "2026-09-20", time_zone: { name: "Asia/Tokyo" } } ].each do |params|
      get world_clock_timeline_path, params: params
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to have_key("error")
    end
  end
end
