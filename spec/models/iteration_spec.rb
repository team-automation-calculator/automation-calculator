require 'rails_helper'

RSpec.describe Iteration, type: :model do
  let(:iteration) { create(:iteration) }

  describe 'validations' do
    context 'with valid model' do
      it 'is valid' do
        expect(iteration).to be_valid
      end
    end

    it { is_expected.to validate_numericality_of(:cost).only_integer }
    it { is_expected.to validate_numericality_of(:cost).is_greater_than(0) }
    it { is_expected.to belong_to(:automation_scenario) }
  end
end
