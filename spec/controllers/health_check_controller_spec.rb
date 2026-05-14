require 'rails_helper'

RSpec.describe HealthCheckController, type: :controller do
  describe '#health' do
    context 'when the database is reachable' do
      it 'returns 200' do
        get :health
        expect(response).to have_http_status(:ok)
      end

      it 'returns json content type' do
        get :health
        expect(response.content_type).to eq('application/json')
      end

      it 'returns a unix timestamp' do
        get :health
        body = JSON.parse(response.body)
        expect(body['current_time_in_unix']).to be_a(Integer)
      end

      it 'returns the short commit hash' do
        get :health
        body = JSON.parse(response.body)
        expect(body['short_commit_hash']).to eq(ENV['SHORT_COMMIT_HASH'])
      end

      it 'returns database ok' do
        get :health
        body = JSON.parse(response.body)
        expect(body['database']).to eq('ok')
      end
    end

    context 'when the database is unreachable' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute)
          .and_raise(PG::ConnectionBad)
      end

      it 'returns 503' do
        get :health
        expect(response).to have_http_status(:service_unavailable)
      end

      it 'returns database unavailable' do
        get :health
        body = JSON.parse(response.body)
        expect(body['database']).to eq('unavailable')
      end

      it 'does not leak sensitive connection details' do
        get :health
        expect(response.body).not_to match(/host|password|user|dbname|connect/i)
      end
    end
  end
end
