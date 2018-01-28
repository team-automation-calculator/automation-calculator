class Visitor < ApplicationRecord
  has_many :automation_scenarios, as: :owner, dependent: :destroy
  validates :ip, :uuid, presence: true
end
