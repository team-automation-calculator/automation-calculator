require 'rails_helper'

# The test environment runs on :null_store, so these build the production
# store directly. Two store objects stand in for two pods: what rate_limit
# needs is that both count in the same place and that the count expires.
RSpec.describe SolidCache::Store do
  include ActiveSupport::Testing::TimeHelpers

  let(:pod_a) { ActiveSupport::Cache.lookup_store(:solid_cache_store) }
  let(:pod_b) { ActiveSupport::Cache.lookup_store(:solid_cache_store) }
  let(:key) { 'rate-limit:api/v1/user_sessions:203.0.113.7' }

  it 'is the production cache store' do
    production_config = Rails.root.join('config/environments/production.rb')

    expect(production_config.read)
      .to match(/^\s*config\.cache_store = :solid_cache_store$/)
  end

  it 'shares one counter between store instances' do
    pod_a.increment(key, 1, expires_in: 1.minute)
    pod_b.increment(key, 1, expires_in: 1.minute)

    expect(pod_a.increment(key, 1, expires_in: 1.minute)).to eq(3)
  end

  it 'keeps the counter in the primary database' do
    expect { pod_a.increment(key, 1, expires_in: 1.minute) }
      .to change(SolidCache::Entry, :count).by(1)
  end

  it 'starts a new count once the window has passed' do
    pod_a.increment(key, 1, expires_in: 1.minute)
    pod_b.increment(key, 1, expires_in: 1.minute)

    travel 61.seconds do
      expect(pod_b.increment(key, 1, expires_in: 1.minute)).to eq(1)
    end
  end
end
