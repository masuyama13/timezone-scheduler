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
    expect(page).to have_text("Add your availability")
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
    expect(page).to have_button("Copy event link")
    expect(page).to have_button("Vancouver (America/Vancouver)")
    click_button "Vancouver (America/Vancouver)"
    fill_in "City or country", with: "Tokyo"
    click_button "Tokyo"
    expect(page).to have_button("Tokyo (Asia/Tokyo)")
    click_button "Add your availability"
    expect(page).to have_text(/\b[A-Z][a-z]{2}, [A-Z][a-z]{2} \d{1,2}, \d{4}, \d{1,2}:\d{2} [AP]M\b/)
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

  it "opens a candidate time modal with unique local times" do
    vancouver_response = event.responses.create!(name: "Alex", time_zone: "America/Vancouver")
    tokyo_response = event.responses.create!(name: "Hana", time_zone: "Asia/Tokyo")
    event.time_options.order(:starts_at).each do |time_option|
      vancouver_response.votes.create!(time_option: time_option, availability: :available)
      tokyo_response.votes.create!(time_option: time_option, availability: :maybe)
    end

    visit event_path(event.public_token)
    find('th[data-candidate-share-column-index="0"]').click

    expect(page).to have_css('[role="dialog"]', visible: true)
    expect(page).to have_text("Selected time")
    expect(page).to have_text("Vancouver")
    expect(page).to have_text("Tokyo")
    expect(page).to have_css('[data-candidate-share-target="times"] p', count: 2)
  end

  it "submits an availability response" do
    click_button "Add your availability"
    fill_in "Name", with: "Alex"
    page.execute_script(<<~JS)
      document.querySelectorAll('input[value="available"]')[0].click()
      document.querySelectorAll('input[value="maybe"]')[1].click()
    JS
    fill_in "Comment", with: "Looking forward to it"
    click_button "Add response"

    expect(page).to have_text("Responses", wait: 5)
    expect(page).to have_text("1 response", wait: 5)
    expect(page).to have_text("Alex", wait: 5)
    expect(page).to have_text("Vancouver", wait: 5)
    expect(page).to have_text("Looking forward to it", wait: 5)
  end
  it "edits an existing availability response" do
    response = event.responses.create!(name: "Alex", time_zone: "America/Vancouver", comment: "Original")
    event.time_options.order(:starts_at).each_with_index do |time_option, index|
      response.votes.create!(time_option: time_option, availability: index.zero? ? "available" : "maybe")
    end

    visit event_path(event.public_token)
    find("button[data-response-id=\"#{response.id}\"]").click

    expect(page).to have_text("Edit your response")
    fill_in "Name", with: "Jordan"
    fill_in "Comment", with: "Updated"
    click_button "Save changes"

    expect(page).to have_text("Jordan", wait: 5)
    expect(page).to have_text("Updated", wait: 5)
  end

  it "deletes an availability response from the edit modal" do
    response = event.responses.create!(name: "Alex", time_zone: "America/Vancouver")
    event.time_options.order(:starts_at).each do |time_option|
      response.votes.create!(time_option: time_option, availability: :available)
    end

    visit event_path(event.public_token)
    find("button[data-response-id=\"#{response.id}\"]").click
    expect(page).to have_button("Delete response")

    dismiss_confirm do
      click_button "Delete response"
    end
    expect(page).to have_text("Alex")

    accept_confirm(/Delete Alex's response\?/) do
      click_button "Delete response"
    end

    expect(page).to have_text("No responses yet.", wait: 5)
  end

  it "keeps page times in the viewer timezone while editing another response" do
    response = event.responses.create!(name: "Tokyo guest", time_zone: "Asia/Tokyo")
    event.time_options.order(:starts_at).each do |time_option|
      response.votes.create!(time_option: time_option, availability: :available)
    end

    visit event_path(event.public_token)
    page_time = find('[data-event-response-target="responseDate"]', match: :first).text
    find("button[data-response-id=\"#{response.id}\"]").click

    expect(find('[data-event-response-target="responseDate"]', match: :first).text).to eq(page_time)
    expect(find('[data-event-response-target="optionDate"]', match: :first).text).to eq(event.time_options.first.starts_at.in_time_zone("Asia/Tokyo").strftime("%a, %b %-d, %Y, %-I:%M %p"))
  end
end
