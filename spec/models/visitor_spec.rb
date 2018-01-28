require 'rails_helper'

RSpec.describe Visitor, type: :model do
  let(:visitor) { create(:visitor) }

  describe 'validations' do
    context 'with valid model' do
      it 'should be valid' do
        expect(visitor.valid?).to be_truthy
      end
    end

    it { should validate_presence_of(:ip) }
    it { should validate_presence_of(:uuid) }
  end
end
