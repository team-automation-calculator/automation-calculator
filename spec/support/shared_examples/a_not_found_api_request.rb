RSpec.shared_examples_for 'a not found api request' do
  it { expect(response.headers['Access-Token']).to be_blank }
  it { expect(response).to have_http_status(:not_found) }
  it { expect(response.body).to be_blank }
end
