require "rails_helper"

RSpec.describe "World Clock", type: :system do
  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1280, 900 ]
    visit root_path
    page.execute_script("window.localStorage.setItem('timezone-scheduler.world-clock', JSON.stringify([{ key: 'tokyo', primary: true }])); window.location.reload()")
  end

  it "renders a 24-hour grid for the selected cities" do
    expect(page).to have_css("[data-time-grid-target='row']", count: 1)
    expect(page).to have_css("[data-time-grid-target='row'] div", minimum: 24)
    expect(page).to have_content("Tokyo")
  end

  it "adds a city from the search modal" do
    open_city_search
    fill_in "City or country", with: "Vancouver"
    find("button[data-city-key='vancouver']").click

    expect(page).to have_content("Vancouver")
    expect(page).to have_content("2 of 10 cities")
  end

  it "prevents adding the same city twice" do
    add_city("Vancouver", "vancouver")
    open_city_search
    fill_in "City or country", with: "Vancouver"

    within('[role="dialog"]') do
      expect(page).not_to have_css("button[data-city-key='vancouver']")
    end
  end

  it "changes the primary city without removing the city list" do
    find("button[aria-label='Change your city']").click
    fill_in "City or country", with: "Vancouver"
    find("button[data-city-key='vancouver']").click

    expect(page).to have_content("Vancouver")
    expect(page).not_to have_content("Tokyo")
    expect(page).to have_css("[data-time-grid-target='row']:first-child", text: /Vancouver/)
  end

  it "does not offer removal for the primary city" do
    expect(page).not_to have_css("button[data-action='click->world-clock#removeCity']")
    expect(page).to have_button("Change")
  end

  it "restores selected cities from localStorage" do
    visit root_path

    expect(page).to have_content("Tokyo")
  end

  it "navigates dates and returns to today in the primary timezone" do
    expect(page).to have_css("[data-instant]", count: 24)
    select_date("2026-12-31")
    expect(page).to have_css('[data-instant="2026-12-30T15:00:00.000Z"]')
    find('button[aria-label="Next day"]').click
    expect(page).to have_field("Comparison date", with: "2027-01-01")
    expect(page).to have_css('[data-instant="2026-12-31T15:00:00.000Z"]')
    find('button[aria-label="Previous day"]').click
    expect(page).to have_field("Comparison date", with: "2026-12-31")
    expect(page).not_to have_button("Today")
  end

  it "aligns city rows and preserves fractional local minutes and date boundaries" do
    add_city("Delhi", "delhi")
    select_date("2026-09-20")
    expect(page).to have_css('[data-instant="2026-09-19T15:00:00.000Z"]', count: 2)
    rows = all("[data-time-grid-target='row']")
    expect(rows[0].all("[data-instant]").map { |cell| cell["data-instant"] }).to eq(
      rows[1].all("[data-instant]").map { |cell| cell["data-instant"] }
    )
    expect(rows[1]).to have_text("8:30 PM")
    expect(rows[1]).to have_text("Sep 19")
    expect(rows[1]).to have_text("Sep 20")
  end

  it "renders missing and repeated hours on transition dates" do
    change_primary_to_new_york
    select_date("2026-03-08")
    expect(page).to have_css("[data-instant]", count: 23)
    expect(page).not_to have_css('[data-instant][aria-label*=", 2:00 AM,"]')
    select_date("2026-11-01")
    expect(page).to have_css("[data-instant]", count: 25)
    expect(page).to have_css('[data-instant][aria-label*=", 1:00 AM,"]', count: 2)
    expect(page).to have_text("GMT-04:00")
    expect(page).to have_text("GMT-05:00")
  end

  it "pages through every instant on mobile and resets the page on date changes" do
    page.current_window.resize_to(390, 844)
    change_primary_to_new_york
    select_date("2026-11-01")
    expect(page).to have_css('[data-instant="2026-11-01T04:00:00.000Z"]')
    expect(page).to have_css("[data-instant]", count: 12)
    expect(page).to have_css('button[aria-label="Show previous 12 hours"][disabled]')
    find('button[aria-label="Show next 12 hours"]').click
    expect(page).to have_css('[data-instant="2026-11-01T16:00:00.000Z"]')
    find('button[aria-label="Show next 12 hours"]').click
    expect(page).to have_css("[data-instant]", count: 1)
    expect(page).to have_css('[data-instant="2026-11-02T04:00:00.000Z"]')
    expect(page).to have_css('button[aria-label="Show next 12 hours"][disabled]')
    find('button[aria-label="Show previous 12 hours"]').click
    expect(page).to have_css("[data-instant]", count: 12)
    find('button[aria-label="Next day"]').click
    expect(page).to have_css('[data-instant="2026-11-02T05:00:00.000Z"]')
    expect(page).to have_css('button[aria-label="Show previous 12 hours"][disabled]')
  ensure
    page.current_window.resize_to(1280, 900)
  end

  it "keeps the displayed grid until the next date has loaded" do
    select_date("2026-09-20")
    expect(page).to have_css('[data-instant="2026-09-19T15:00:00.000Z"]')
    page.execute_script(<<~JS)
      const originalFetch = window.fetch;
      window.fetch = (...args) => new Promise((resolve, reject) => {
        window.finishTimelineRequest = () => originalFetch(...args).then(resolve, reject);
      });
    JS
    select_date("2026-09-21")
    expect(page).to have_css("[data-instant]", count: 24)
    expect(page).to have_css('[data-instant="2026-09-19T15:00:00.000Z"]')
    expect(page).not_to have_text("Loading")
    page.execute_script("window.finishTimelineRequest()")
    expect(page).to have_css('[data-instant="2026-09-20T15:00:00.000Z"]')
    expect(page).not_to have_css('[data-instant="2026-09-19T15:00:00.000Z"]')
  end

  it "clears stale times after a failed request and allows retrying" do
    expect(page).to have_css("[data-instant]", count: 24)
    page.execute_script("window.originalFetch = window.fetch; window.fetch = () => Promise.reject(new Error('offline'))")
    select_date("2027-02-01")
    expect(page).to have_text("Could not load this date.")
    expect(page).not_to have_css("[data-instant]")
    page.execute_script("window.fetch = window.originalFetch")
    click_button "Retry"
    expect(page).to have_css('[data-instant="2027-01-31T15:00:00.000Z"]')
    expect(page).not_to have_button("Retry")
  end

  it "opens a minute-level preview from a time cell" do
    first("[data-instant]").click
    expect(page).to have_css('[role="dialog"]', visible: true)
    expect(page).to have_field("Date")
    expect(page).to have_field("Time")
    expect(page).to have_text("Tokyo")
    fill_in "Time", with: "00:17"
    expect(page).to have_text("12:17 AM")
  end

  it "adds, deduplicates, and removes selected times" do
    first("[data-instant]").click
    click_button "Add this time"

    expect(page).to have_text("1 of 10 times selected")
    expect(page).to have_button("Already selected", disabled: true)
    expect(page).not_to have_text("Remove")

    click_button "Close"
    first("[data-instant]").click
    expect(page).to have_button("Already selected", disabled: true)
    click_button "Close"
    find("button[aria-label='Remove selected time 1']").click

    expect(page).not_to have_text("1 of 10 times selected")
    expect(page).to have_no_css("[data-candidate-times-target='list'] button")
  end

  it "reviews selected times after choosing at least two" do
    expect(page).not_to have_button("Review selected times")

    first("[data-instant]").click
    click_button "Add this time"
    click_button "Close"
    expect(page).not_to have_button("Review selected times")
    click_button "Plan a meeting"
    expect(page).to have_text("Select at least two time options before planning a meeting.")

    all("[data-instant]")[1].click
    click_button "Add this time"
    click_button "Close"
    expect(page).to have_button("Review selected times", disabled: false)
    click_button "Review selected times"

    expect(page).to have_css('[aria-labelledby="review-times-heading"]', visible: true)
    expect(page).to have_text("1.")
    expect(page).to have_text("2.")
    expect(page).to have_text("Tokyo")
  end

  it "validates selected times from the review modal" do
    select_date((Date.current + 2).iso8601)
    expect(page).to have_text("12 AM")
    first("[data-instant]").click
    click_button "Add this time"
    click_button "Close"
    all("[data-instant]")[1].click
    click_button "Add this time"
    click_button "Close"
    click_button "Plan a meeting"

    expect(page).to have_css('[aria-labelledby="review-times-heading"]', visible: true)
    expect(page).not_to have_css('[aria-labelledby="candidate-time-heading"]', visible: true)
  end

  private

  def select_date(value)
    page.execute_script(<<~JS, value)
      const input = document.querySelector("#comparison-date");
      input.value = arguments[0];
      input.dispatchEvent(new Event("change", { bubbles: true }));
    JS
  end

  def change_primary_to_new_york
    click_button "Change your city"
    fill_in "City or country", with: "New York"
    find("button[data-city-key='new-york']").click
    expect(page).to have_text("New York")
  end

  def open_city_search
    click_button "Add city"
    expect(page).to have_css('[role="dialog"]', visible: true)
  end

  def add_city(name, key)
    open_city_search
    fill_in "City or country", with: name
    find("button[data-city-key='#{key}']").click
  end
end
