# == Schema Information
#
# Table name: time_options
#
#  id         :bigint           not null, primary key
#  starts_at  :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  event_id   :bigint           not null
#
# Indexes
#
#  index_time_options_on_event_id                (event_id)
#  index_time_options_on_event_id_and_starts_at  (event_id,starts_at) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (event_id => events.id)
#
class TimeOption < ApplicationRecord
  belongs_to :event
end
