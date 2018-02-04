require 'rails_helper'

RSpec.describe Visitor, type: :model do
  let(:visitor) { create(:visitor) }

  describe 'validations' do
    context 'with valid model' do
      it 'is valid' do
        expect(visitor).to be_valid
      end
    end

    it { is_expected.to validate_presence_of(:ip) }
    it { is_expected.to validate_presence_of(:uuid) }
  end
end
