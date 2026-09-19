require 'rails_helper'

# == Schema Information
#
# Table name: responses
#
#  id         :bigint           not null, primary key
#  comment    :text
#  name       :string           not null
#  time_zone  :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  event_id   :bigint           not null
#
# Indexes
#
#  index_responses_on_event_id  (event_id)
#
# Foreign Keys
#
#  fk_rails_...  (event_id => events.id)
#
RSpec.describe Response, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
