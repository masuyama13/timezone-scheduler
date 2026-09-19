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
FactoryBot.define do
  factory :event do
    name { "MyString" }
    description { "MyText" }
    time_zone { "MyString" }
    public_token { "MyString" }
  end
end
