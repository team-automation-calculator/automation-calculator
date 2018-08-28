RSpec.shared_examples_for 'an unauthenticated api request' do
  it { expect(response.headers['Access-Token']).to be_blank }
  it { expect(response).to have_http_status(:unauthorized) }
  it { expect(response.body).to be_blank }
end
