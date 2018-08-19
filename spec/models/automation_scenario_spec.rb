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
end
