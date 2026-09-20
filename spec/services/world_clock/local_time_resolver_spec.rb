require "rails_helper"

RSpec.describe WorldClock::LocalTimeResolver do
  def resolve(date, zone, hour, minute = 0)
    described_class.new(date: date, time_zone: zone).call(hour: hour, minute: minute)
  end

  it "preserves exact minutes and returns UTC with zero seconds" do
    [ 0, 17, 59 ].each do |minute|
      expect(resolve("2026-09-20", "Asia/Tokyo", 15, minute)).to eq([ Time.utc(2026, 9, 20, 6, minute) ])
    end
  end

  it "does not normalize nonexistent times" do
    expect(resolve("2026-03-08", "America/New_York", 2, 17)).to be_empty
  end

  it "returns both occurrences in chronological order" do
    expect(resolve("2026-11-01", "America/New_York", 1, 17)).to eq([
      Time.utc(2026, 11, 1, 5, 17), Time.utc(2026, 11, 1, 6, 17)
    ])
  end

  it "handles half-hour gaps and repeated times" do
    expect(resolve("2026-10-04", "Australia/Lord_Howe", 2, 17)).to be_empty
    expect(resolve("2026-04-05", "Australia/Lord_Howe", 1, 45)).to eq([
      Time.utc(2026, 4, 4, 14, 45), Time.utc(2026, 4, 4, 15, 15)
    ])
  end

  it "preserves half-hour and quarter-hour offsets across dates" do
    expect(resolve("2026-09-20", "Asia/Kolkata", 0)).to eq([ Time.utc(2026, 9, 19, 18, 30) ])
    expect(resolve("2026-09-20", "Asia/Kathmandu", 0)).to eq([ Time.utc(2026, 9, 19, 18, 15) ])
  end

  it "accepts Date values and dates more than a year ahead" do
    expect(resolve(Date.new(2030, 1, 1), "Etc/UTC", 0)).to eq([ Time.utc(2030, 1, 1) ])
  end

  it "rejects invalid dates rather than normalizing them" do
    [ "2026-02-30", "2026-09-20junk", "20260920", nil ].each do |date|
      expect { resolve(date, "Etc/UTC", 0) }.to raise_error(ArgumentError)
    end
  end

  it "rejects invalid clock fields" do
    [ [ 24, 0 ], [ -1, 0 ], [ 1, 60 ], [ 1, -1 ], [ "1", 0 ], [ 1, 0.5 ] ].each do |hour, minute|
      expect { resolve("2026-09-20", "Etc/UTC", hour, minute) }.to raise_error(ArgumentError)
    end
  end

  it "rejects unknown timezone identifiers" do
    expect { resolve("2026-09-20", "Invalid/Zone", 0) }.to raise_error(TZInfo::InvalidTimezoneIdentifier)
  end
end
