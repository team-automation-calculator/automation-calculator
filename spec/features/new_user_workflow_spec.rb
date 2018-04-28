require 'rails_helper'
RSpec.describe 'New user workflow', type: :feature do
  def visitors_path
    visit '/visitors'
  end
  context 'when visit the /visitors path' do
    before { visitors_path }

    it 'creates new visitor' do
      expect { visitors_path }.to change(Visitor, :count).by(1)
    end

    it 'creates new automation scenario' do
      expect { visitors_path }.to change(AutomationScenario, :count).by(1)
    end

    it "redirects visitor to automation scenario's show page" do
      expect(page).to have_content('AutomationScenario')
    end

    it 'sets blank array of scenario solution' do
      expect(page).to have_css('#scenarioSolutions', text: [], visible: false)
    end
  end

  context 'when create the solution for the scenario' do
    before { visitors_path }
    let(:solutions) { AutomationScenario.last.solutions }

    it 'sets soulution in hidden field' do
      fill_in 'solution_initial_cost', with: 1
      fill_in 'solution_iteration_cost', with: 10
      fill_in 'solution_iteration_count', with: 10
      click_button 'Save Solution'
      expect(page).to have_css('#scenarioSolutions', text: solutions.to_json, visible: false)
    end
  end
end
