class Schedule < ApplicationRecord
  enum :status, { pending: "pending", confirmed: "confirmed", rejected: "rejected" }

  validates :slots, presence: true
  validates :timezone, presence: true
  validates :status, presence: true
end
