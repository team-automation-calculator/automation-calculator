require 'rails_helper'

RSpec.describe Solution, type: :model do
  let(:solution) { create(:solution) }

  describe 'validations' do
    context 'with valid model' do
      it 'should be valid' do
        expect(solution.valid?).to be_truthy
      end
    end

    it { should validate_numericality_of(:initial_cost).only_integer }
    it { should validate_numericality_of(:initial_cost).is_greater_than(0) }
    it { should validate_numericality_of(:iteration_cost).only_integer }
    it { should validate_numericality_of(:iteration_cost).is_greater_than(0) }
    it { should validate_numericality_of(:iteration_count).only_integer }
    it { should validate_numericality_of(:iteration_count).is_greater_than(0) }
    it { should belong_to(:automation_scenario) }
  end
end
