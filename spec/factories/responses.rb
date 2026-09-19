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
FactoryBot.define do
  factory :response do
    event { nil }
    name { "MyString" }
    time_zone { "MyString" }
    comment { "MyText" }
  end
end
