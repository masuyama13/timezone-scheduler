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
class Response < ApplicationRecord
  belongs_to :event
  has_many :votes, dependent: :destroy

  validates :name, presence: true, length: { maximum: 50 }
  validates :time_zone, presence: true
  validates :comment, length: { maximum: 400 }
end
