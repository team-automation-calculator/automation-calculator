class Visitor < ApplicationRecord
  has_many  :automation_scenarios,
            as: :owner,
            dependent: :destroy,
            inverse_of: :owner
  validates :ip, :uuid, presence: true

  def self.create_with_random_uuid(ip_address)
    create uuid: SecureRandom.uuid, ip: ip_address
  end
end

# == Schema Information
#
# Table name: visitors
#
#  id         :bigint(8)        not null, primary key
#  ip         :string
#  uuid       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
