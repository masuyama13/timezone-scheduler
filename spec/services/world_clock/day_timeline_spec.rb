require "rails_helper"

RSpec.describe WorldClock::DayTimeline do
  def timeline(date, zone)
    described_class.new(date: date, time_zone: zone).call
  end

  it "covers a normal local day from midnight to 11 PM" do
    expect(timeline("2026-09-20", "Asia/Tokyo")).to eq(
      Array.new(24) { |hour| Time.utc(2026, 9, 19, 15) + hour.hours }
    )
  end

  it "omits the missing hour on the spring transition" do
    times = timeline("2026-03-08", "America/New_York")
    expect(times).to eq(Array.new(23) { |hour| Time.utc(2026, 3, 8, 5) + hour.hours })
    expect(times.map { |time| TZInfo::Timezone.get("America/New_York").to_local(time).hour }).not_to include(2)
  end

  it "keeps both repeated hours on the autumn transition" do
    times = timeline("2026-11-01", "America/New_York")
    expect(times).to eq(Array.new(25) { |hour| Time.utc(2026, 11, 1, 4) + hour.hours })
    repeated = times.select { |time| TZInfo::Timezone.get("America/New_York").to_local(time).hour == 1 }
    expect(repeated).to eq([ Time.utc(2026, 11, 1, 5), Time.utc(2026, 11, 1, 6) ])
  end

  it "includes the partial hour following a half-hour forward transition" do
    times = timeline("2026-10-04", "Australia/Lord_Howe")
    local = times.map { |time| TZInfo::Timezone.get("Australia/Lord_Howe").to_local(time).strftime("%H:%M") }
    expect(local).to eq([ "00:00", "01:00", "02:30" ] + (3..23).map { |hour| "%02d:00" % hour })
    expect(times.each_cons(2).map { |a, b| b - a }).to include(1800)
  end

  it "includes the repeated partial hour following a half-hour backward transition" do
    times = timeline("2026-04-05", "Australia/Lord_Howe")
    local = times.map { |time| TZInfo::Timezone.get("Australia/Lord_Howe").to_local(time).strftime("%H:%M") }
    expect(local).to eq([ "00:00", "01:00", "01:30" ] + (2..23).map { |hour| "%02d:00" % hour })
    expect(times).to eq(times.sort.uniq)
  end

  it "keeps fractional offsets when displaying a shared instant in another city" do
    instant = timeline("2026-09-20", "Asia/Tokyo").first
    expect(TZInfo::Timezone.get("Asia/Kolkata").to_local(instant).strftime("%F %H:%M")).to eq("2026-09-19 20:30")
    expect(TZInfo::Timezone.get("Asia/Kathmandu").to_local(instant).strftime("%F %H:%M")).to eq("2026-09-19 20:45")
  end

  it "starts after a nonexistent midnight" do
    times = timeline("2018-11-04", "America/Sao_Paulo")
    expect(times.length).to eq(23)
    expect(times.first).to eq(Time.utc(2018, 11, 4, 3))
  end

  it "returns no instants for an entirely skipped date" do
    expect(timeline("2011-12-30", "Pacific/Apia")).to be_empty
  end
end
