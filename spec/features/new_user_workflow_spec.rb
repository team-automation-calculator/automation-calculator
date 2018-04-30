require 'rails_helper'
RSpec.describe 'New user workflow', type: :feature do
  def visit_visitors_path
    visit '/visitors'
  end

  context 'when visit the /visitors path' do
    before { visit_visitors_path }

    it 'creates new visitor' do
      expect { visit_visitors_path }.to change(Visitor, :count).by(1)
    end

    it 'creates new automation scenario' do
      expect { visit_visitors_path }.to change(AutomationScenario, :count).by(1)
    end

    it "redirects visitor to automation scenario's show page" do
      expect(page).to have_content('AutomationScenario')
    end

    it 'sets blank array of scenario solution' do
      expect(page).to have_css('#scenarioSolutions', text: [], visible: false)
    end
  end

  context 'when create the solution for the scenario' do
    before do
      visit_visitors_path

      fill_in 'automation_scenario_solutions_attributes_0_initial_cost', with: 1
      fill_in 'automation_scenario_solutions_attributes_0_iteration_cost', with: 10
      fill_in 'automation_scenario_iteration_count', with: 10
      click_button 'Update Automation scenario'
    end

    it 'sets soulutions in hidden field' do
      expect(page).to have_css(
        '#scenarioSolutions',
        text: { initial_cost: 1, iteration_cost: 10, iteration_count: 10 }.to_json,
        visible: false
      )
    end
  end
end
