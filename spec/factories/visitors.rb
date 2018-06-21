FactoryBot.define do
  factory :visitor do
    ip    { Faker::Internet.ip_v4_address }
    uuid  { SecureRandom.uuid }
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
