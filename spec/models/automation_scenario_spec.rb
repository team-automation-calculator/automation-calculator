require 'rails_helper'

RSpec.describe AutomationScenario, type: :model do
  subject(:automation_scenario) { create(:automation_scenario) }

  describe 'validations' do
    it { is_expected.to belong_to(:owner) }

    specify do
      is_expected.to validate_numericality_of(:iteration_count).only_integer
    end

    specify do
      is_expected
        .to validate_numericality_of(:iteration_count)
        .is_greater_than(0)
    end
  end

  describe '.solutions_combinations' do
    before do
      create_list :solution, solution_count,
                  automation_scenario: automation_scenario
    end

    context 'with 2 solutions' do
      let(:solution_count) { 2 }

      its('solutions_combinations.size') { is_expected.to eq 1 }
    end

    context 'with 3 solutions' do
      let(:solution_count) { 3 }

      its('solutions_combinations.size') { is_expected.to eq 3 }
    end
  end
end
