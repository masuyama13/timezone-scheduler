require "rails_helper"

RSpec.describe "World Clock", type: :request do
  describe "GET /" do
    it "renders the World Clock city management screen" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Timezone Scheduler")
      expect(response.body).to include('id="world-clock-heading"')
      expect(response.body).to include("Select cities")
      expect(response.body).to include("Add city")
      expect(response.body).to include("Plan a meeting")
    end
  end
end
