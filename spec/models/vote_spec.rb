require 'rails_helper'

# == Schema Information
#
# Table name: votes
#
#  id             :bigint           not null, primary key
#  availability   :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  response_id    :bigint           not null
#  time_option_id :bigint           not null
#
# Indexes
#
#  index_votes_on_response_id     (response_id)
#  index_votes_on_time_option_id  (time_option_id)
#
# Foreign Keys
#
#  fk_rails_...  (response_id => responses.id)
#  fk_rails_...  (time_option_id => time_options.id)
#
RSpec.describe Vote, type: :model do
  it "supports the three availability states" do
    expect(described_class.availabilities).to eq(
      "unavailable" => 0,
      "available" => 1,
      "maybe" => 2
    )
  end

  it "rejects an unknown availability state" do
    vote = described_class.new(availability: "unknown")

    expect(vote).not_to be_valid
    expect(vote.errors[:availability]).to include("is not included in the list")
  end
end
