FactoryBot.define do
  factory :visitor do
    ip '192.168.1.1'
    uuid { SecureRandom.uuid }
  end
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
