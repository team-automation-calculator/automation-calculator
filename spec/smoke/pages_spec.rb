require 'smoke_helper'

RSpec.describe 'Pages', :smoke do
  describe 'GET /users/sign_in' do
    it 'returns 200' do
      response = smoke_get('/users/sign_in')
      expect(response.code.to_i).to eq(200)
    end

    it 'includes a login form' do
      response = smoke_get('/users/sign_in')
      doc = Nokogiri::HTML(response.body)
      email_sel = "input[type='email'], input[autocomplete='email']"
      expect(doc.at_css(email_sel)).not_to be_nil
      expect(doc.at_css("input[type='password']")).not_to be_nil
    end
  end

  describe 'GET /visitor' do
    it 'redirects (does not 5xx)' do
      response = smoke_get('/visitor')
      expect(response.code.to_i).to be_between(300, 399)
    end
  end

  describe 'GET /about' do
    it 'returns 200' do
      response = smoke_get('/about')
      expect(response.code.to_i).to eq(200)
    end

    it 'includes about content' do
      response = smoke_get('/about')
      doc = Nokogiri::HTML(response.body)
      expect(doc.at_xpath("//*[contains(text(),'About')]")).not_to be_nil
    end
  end

  describe 'GET /privacy' do
    it 'returns 200' do
      response = smoke_get('/privacy')
      expect(response.code.to_i).to eq(200)
    end

    it 'includes privacy policy content' do
      response = smoke_get('/privacy')
      doc = Nokogiri::HTML(response.body)
      expect(doc.at_xpath("//*[contains(text(),'Privacy')]")).not_to be_nil
    end
  end

  describe 'GET /users/sign_up' do
    it 'returns 200' do
      response = smoke_get('/users/sign_up')
      expect(response.code.to_i).to eq(200)
    end

    it 'includes a registration form' do
      response = smoke_get('/users/sign_up')
      doc = Nokogiri::HTML(response.body)
      email_sel = "input[type='email'], input[autocomplete='email']"
      expect(doc.at_css(email_sel)).not_to be_nil
      expect(doc.at_css("input[type='password']")).not_to be_nil
    end
  end
end
