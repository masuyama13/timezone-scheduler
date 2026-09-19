class Vote < ApplicationRecord
  belongs_to :response
  belongs_to :time_option
end
