require 'rails_helper'

RSpec.describe AutomationScenario, type: :model do
  let(:scenario) { create(:automation_scenario) }

  describe 'validations' do
    context 'with valid model' do
      it 'should be valid' do
        expect(scenario.valid?).to be_truthy
      end
    end

    it { should belong_to(:owner) }
  end
end
