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
class Vote < ApplicationRecord
  belongs_to :response
  belongs_to :time_option
end
