require "rails_helper"

RSpec.describe "World Clock time resolutions", type: :request do
  it "resolves an exact local minute" do
    get world_clock_time_resolution_path, params: { date: "2026-09-20", time: "15:17", time_zone: "Asia/Tokyo" }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("instants")).to eq([ "2026-09-20T06:17:00Z" ])
  end

  it "returns no instant for a nonexistent local time" do
    get world_clock_time_resolution_path, params: { date: "2026-03-08", time: "02:17", time_zone: "America/New_York" }
    expect(response.parsed_body.fetch("instants")).to eq([])
  end

  it "returns both instants for an ambiguous local time" do
    get world_clock_time_resolution_path, params: { date: "2026-11-01", time: "01:17", time_zone: "America/New_York" }
    expect(response.parsed_body.fetch("instants")).to eq([ "2026-11-01T05:17:00Z", "2026-11-01T06:17:00Z" ])
  end

  it "rejects invalid parameters" do
    get world_clock_time_resolution_path, params: { date: "2026-09-20", time: "25:00", time_zone: "Asia/Tokyo" }
    expect(response).to have_http_status(:unprocessable_content)
  end
end
