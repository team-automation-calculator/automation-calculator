class Visitor < ApplicationRecord
  has_many :automation_scenarios, as: :owner, dependent: :destroy
  validates :ip, :uuid, presence: true
end

# == Schema Information
#
# Table name: visitors
#
#  id         :integer          not null, primary key
#  ip         :string
#  uuid       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
