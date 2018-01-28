FactoryBot.define do
  factory :visitor do
    ip '192.168.1.1'
    uuid { SecureRandom.uuid }
  end
end
