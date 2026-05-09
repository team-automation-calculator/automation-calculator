require 'smoke_helper'

RSpec.describe 'App liveness', :smoke do
  describe 'GET /health' do
    it 'returns 200' do
      response = smoke_get('/health')
      expect(response.code.to_i).to eq(200)
    end

    it 'returns valid JSON' do
      response = smoke_get('/health')
      expect { JSON.parse(response.body) }.not_to raise_error
    end
  end

  describe 'GET /' do
    it 'landing page returns 200' do
      response = smoke_get('/')
      expect(response.code.to_i).to eq(200)
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
