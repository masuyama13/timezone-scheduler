require 'rails_helper'

# == Schema Information
#
# Table name: votes
#
#  id             :bigint           not null, primary key
#  available      :boolean          not null
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
  pending "add some examples to (or delete) #{__FILE__}"
end
