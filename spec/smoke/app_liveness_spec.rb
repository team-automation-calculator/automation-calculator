require 'smoke_helper'

RSpec.describe 'App liveness', :smoke do
  let(:forged_forwarded_host) { { 'X-Forwarded-Host' => 'attacker.example' } }

  describe 'GET /health' do
    it 'returns 200' do
      response = smoke_get('/health')
      expect(response.code.to_i).to eq(200)
    end

    it 'returns valid JSON' do
      response = smoke_get('/health')
      expect { JSON.parse(response.body) }.not_to raise_error
    end

    # The kubelet and ALB probes reach the pod by IP, so /health is
    # excluded from Rails host authorization.
    it 'returns 200 with a forged X-Forwarded-Host' do
      response = smoke_get('/health', headers: forged_forwarded_host)
      expect(response.code.to_i).to eq(200)
    end
  end

  describe 'GET /' do
    it 'landing page returns 200' do
      response = smoke_get('/')
      expect(response.code.to_i).to eq(200)
    end

    # The ALB passes X-Forwarded-Host through untouched; Rails host
    # authorization answers 403 rather than building URLs from it.
    it 'landing page is blocked (403) with a forged X-Forwarded-Host' do
      response = smoke_get('/', headers: forged_forwarded_host)
      expect(response.code.to_i).to eq(403)
    end

    it 'landing page includes visitor entry point' do
      response = smoke_get('/')
      doc = Nokogiri::HTML(response.body)
      upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
      lower = upper.downcase
      xpath = "//*[contains(translate(text(),'#{upper}','#{lower}'),'guest')]" \
              " | //*[@href[contains(.,'visitor')]]"
      entry = doc.at_xpath(xpath)
      expect(entry).not_to be_nil
    end
  end

  describe 'API routing' do
    it 'returns 401 (not 5xx) for unauthenticated API requests' do
      response = smoke_v1_get('/api/automation_scenarios')
      expect(response.code.to_i).to eq(401)
    end

    it 'returns valid JSON on 401' do
      response = smoke_v1_get('/api/automation_scenarios')
      expect { JSON.parse(response.body) }.not_to raise_error
    end
  end
end
