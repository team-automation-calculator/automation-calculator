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

  describe '.intersections_and_differences' do
    subject(:intersections) do
      automation_scenario.intersections_and_differences
    end

    context 'when lines are parallel' do
      let(:iteration_cost) { rand 1..100 }
      let!(:solution1) do
        create  :solution,
                automation_scenario: automation_scenario,
                initial_cost: 20,
                iteration_cost: iteration_cost
      end
      let!(:solution2) do
        create  :solution,
                automation_scenario: automation_scenario,
                initial_cost: 45,
                iteration_cost: iteration_cost
      end

      its(:size) { is_expected.to eq 1 }
      its(:first) do
        is_expected.to contain_exactly(
          solution1.id, solution2.id, nil, -25
        )
      end
    end

    context 'when 2 lines intersect on an iteration point' do
      let!(:solution1) do
        create  :solution,
                automation_scenario: automation_scenario,
                initial_cost: 20,
                iteration_cost: 10
      end
      let!(:solution2) do
        create  :solution,
                automation_scenario: automation_scenario,
                initial_cost: 30,
                iteration_cost: 5
      end

      its(:size) { is_expected.to eq 1 }
      its(:first) do
        is_expected.to contain_exactly(
          solution1.id, solution2.id, [2, 40], 40
        )
      end
    end

    context 'when 2 lines intersect between iterations' do
      let!(:solution1) do
        create  :solution,
                automation_scenario: automation_scenario,
                initial_cost: 20,
                iteration_cost: 10
      end
      let!(:solution2) do
        create  :solution,
                automation_scenario: automation_scenario,
                initial_cost: 30,
                iteration_cost: 6
      end

      its(:size) { is_expected.to eq 1 }
      its(:first) do
        is_expected.to contain_exactly(
          solution1.id, solution2.id, [2.5, 45], 30
        )
      end
    end

    context 'when 2 lines intersect out of boundaries' do
      let!(:solution1) do
        create  :solution,
                automation_scenario: automation_scenario,
                initial_cost: 20,
                iteration_cost: 11
      end
      let!(:solution2) do
        create  :solution,
                automation_scenario: automation_scenario,
                initial_cost: 300,
                iteration_cost: 10
      end

      its(:size) { is_expected.to eq 1 }
      its(:first) do
        is_expected.to contain_exactly(
          solution1.id, solution2.id, nil, -270
        )
      end
    end
  end
end
