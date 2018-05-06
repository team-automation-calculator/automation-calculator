require 'rails_helper'

RSpec.describe SolutionTuple, type: :class do
  before do
    create(:solution, initial_cost: 2)
    create(:solution, initial_cost: 3)
  end

  let!(:solution_two) { create(:solution, initial_cost: 1) }

  describe '#list' do
    it 'returns solutions in ascending order by its cost' do
      solutions = Solution.includes(:automation_scenario)
      ordered_solutions = SolutionTuple.new(solutions).list
      expect(ordered_solutions.first).to eq solution_two
    end
  end
end
