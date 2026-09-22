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
    expect(page.evaluate_script(<<~JS)).to be(true)
      (() => {
        const form = document.querySelector('[aria-labelledby="response-heading"]')
        const responses = document.querySelector('[aria-labelledby="responses-heading"]')
        return Boolean(form && responses && (responses.compareDocumentPosition(form) & Node.DOCUMENT_POSITION_FOLLOWING))
      })()
    JS
    expect(page).to have_text("Choose a time")
    expect(page).to have_text("Vancouver")
    expect(page).to have_text("Tokyo")
    expect(page).to have_button("Copy link")
    expect(page).to have_field(type: "text", with: /\/events\/#{event.public_token}/)
    expect(page).to have_select("Your time zone", with_options: [ "Tokyo (Asia/Tokyo)" ])
    expect(page).to have_css('textarea#response-comment[rows="2"]')
    expect(page).to have_text("This page and its responses may be deleted after one year.")
    expect(page).to have_text("No responses yet.")
  end


  it "shows response counts and details" do
    response = event.responses.create!(name: "Alex", time_zone: "America/Vancouver", comment: "Looking forward to it")
    event.time_options.order(:starts_at).each_with_index do |time_option, index|
      response.votes.create!(time_option: time_option, availability: index.zero? ? "available" : "maybe")
    end

    visit event_path(event.public_token)

    expect(page).to have_text("Responses")
    expect(page).to have_text("1 response")
    expect(page).to have_text("Available")
    expect(page).to have_css('[aria-label="Available"]', minimum: 1)
    expect(page).to have_css('[aria-label="Maybe"]', minimum: 1)
    expect(page).to have_text("Alex")
    expect(page).to have_text("Vancouver")
    expect(page).to have_text("Looking forward to it")
  end

  it "submits an availability response" do
    fill_in "Name", with: "Alex"
    page.execute_script(<<~JS)
      document.querySelectorAll('input[value="available"]')[0].click()
      document.querySelectorAll('input[value="maybe"]')[1].click()
    JS
    fill_in "Comment", with: "Looking forward to it"
    click_button "Submit"

    expect(page).to have_text("Responses")
    expect(page).to have_text("1 response")
    expect(page).to have_text("Alex")
    expect(page).to have_text("Vancouver")
    expect(page).to have_text("Looking forward to it")
  end
end
