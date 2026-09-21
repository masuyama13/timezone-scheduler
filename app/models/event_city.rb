class EventCity < ApplicationRecord
  belongs_to :event

  validates :city_key, :name, :region, :time_zone, presence: true
end
