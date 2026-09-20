require "rails_helper"

RSpec.describe "World Clock", type: :system do
  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1280, 900 ]
    visit root_path
    page.execute_script("window.localStorage.setItem('timezone-scheduler.world-clock', JSON.stringify([{ key: 'tokyo', primary: true }])); window.location.reload()")
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
  end

  it "does not offer removal for the primary city" do
    expect(page).not_to have_css("button[data-action='click->world-clock#removeCity']")
    expect(page).to have_button("Change")
  end

  it "restores selected cities from localStorage" do
    visit root_path

    expect(page).to have_content("Tokyo")
  end

  private

  def open_city_search
    click_button "Add City"
    expect(page).to have_css('[role="dialog"]', visible: true)
  end

  def add_city(name, key)
    open_city_search
    fill_in "City or country", with: name
    find("button[data-city-key='#{key}']").click
  end
end
