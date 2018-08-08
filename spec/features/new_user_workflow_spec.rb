require 'rails_helper'
RSpec.describe 'New user workflow', type: :feature do
  def visit_visitor_path
    Capybara.reset_session!
    visit '/'
    click_on 'Visit as a guest'
  end

  context 'when visit the /visitors path' do
    before { visit_visitor_path }

    it 'creates new visitor' do
      expect { visit_visitor_path }.to change(Visitor, :count).by(1)
    end

    it 'creates new automation scenario' do
      expect { visit_visitor_path }.to change(AutomationScenario, :count).by(1)
    end

    it "redirects visitor to automation scenario's show page" do
      expect(page).to have_content('Automation Scenario')
    end

    context 'when inspecting the automation json data' do
      let(:json_scenario_data) do
        {
          iteration_count: 10,
          display_name: "Automation Scenario ##{AutomationScenario.last.id}",
          intersections: [],
          solutions: []
        }.to_json
      end

      it 'sets blank array of scenario solution' do
        expect(page).to have_css(
          '#scenarioData',
          text: json_scenario_data,
          visible: false
        )
      end
    end
  end

  context 'when create the solution for the scenario' do
    before do
      visit_visitor_path

      fill_in 'automation_scenario_solutions_attributes_0_initial_cost',
              with: 1
      fill_in 'automation_scenario_solutions_attributes_0_iteration_cost',
              with: 10
      fill_in 'automation_scenario_iteration_count', with: 10
      click_button 'Update Automation Scenario'
    end

    let(:last_scenario) { AutomationScenario.last }
    let(:json_solutions) do
      {
        iteration_count: 10,
        display_name: "Automation Scenario ##{last_scenario.id}",
        intersections: [],
        solutions: [
          {
            initial_cost: 1,
            iteration_cost: 10,
            iteration_count: 10,
            display_name: "Solution ##{last_scenario.solutions.last.id}"
          }
        ]
      }.to_json
    end

    it 'sets soulutions in hidden field' do
      expect(page).to have_css(
        '#scenarioData',
        text: json_solutions,
        visible: false
      )
    end
  end
end
