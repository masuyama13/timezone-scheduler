require "rails_helper"

RSpec.describe "Shared event", type: :system do
  let!(:event) do
    Events::Create.new(
      name: "Planning session",
      description: "Choose a time",
      time_zone: "America/Vancouver",
      cities: [
        { key: "vancouver", name: "Vancouver", region: "Canada", time_zone: "America/Vancouver", is_primary: true },
        { key: "tokyo", name: "Tokyo", region: "Japan", time_zone: "Asia/Tokyo", is_primary: false }
      ],
      instants: [ 2.hours.from_now.iso8601, 3.hours.from_now.iso8601 ]
    ).call.event
  end

  before do
    driven_by :selenium_chromium, screen_size: [ 1280, 900 ]
    visit event_path(event.public_token)
  end

  it "shows the saved event and its share link" do
    expect(page).to have_text("Planning session")
    expect(page).to have_text("Share your availability")
    expect(page).to have_text("Choose a time")
    expect(page).to have_text("Vancouver")
    expect(page).to have_text("Tokyo")
    expect(page).to have_button("Copy link")
    expect(page).to have_field(type: "text", with: /\/events\/#{event.public_token}/)
    expect(page).to have_select("Your time zone", with_options: [ "Tokyo (Asia/Tokyo)" ])
    expect(page).to have_field("Comment", rows: 2)
    expect(page).to have_text("This page and its responses may be deleted after one year.")
  end


  it "submits an availability response" do
    fill_in "Name", with: "Alex"
    choose "Available", match: :first
    choose "Maybe", match: :first
    fill_in "Comment", with: "Looking forward to it"
    click_button "Submit"

    expect(page).to have_text("Availability submitted.")
    expect(event.responses.count).to eq(1)
    expect(event.responses.first.votes.pluck(:availability)).to contain_exactly("available", "maybe")
  end
end
