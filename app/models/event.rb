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
class Event < ApplicationRecord
  has_many :event_cities, dependent: :destroy
  has_many :time_options, dependent: :destroy
  has_many :responses, dependent: :destroy
end
