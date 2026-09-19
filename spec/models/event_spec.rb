require 'rails_helper'

# == Schema Information
#
# Table name: events
#
#  id           :bigint           not null, primary key
#  description  :text
#  name         :string           not null
#  public_token :string           not null
#  time_zone    :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_events_on_public_token  (public_token) UNIQUE
#
RSpec.describe Event, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
