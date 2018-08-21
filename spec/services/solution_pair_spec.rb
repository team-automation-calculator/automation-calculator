require 'rails_helper'

RSpec.describe SolutionPair, type: :class do
  subject(:solution_pair) { described_class.new solution1, solution2 }

  context 'when solutions are from different scenarios' do
    let(:solution1) { create :solution }
    let(:solution2) { create :solution }

    it 'fails on initialization' do
      expect { solution_pair }
        .to raise_error SolutionPair::UnpairedSolutionsError
    end
  end

  context 'when solutions are from the same scenario' do
    let(:automation_scenario) do
      create :automation_scenario, iteration_count: 10
    end
    let(:solution1) do
      create  :solution,
              automation_scenario: automation_scenario,
              initial_cost: initial_cost1,
              iteration_cost: iteration_cost1
    end
    let(:solution2) do
      create  :solution,
              automation_scenario: automation_scenario,
              initial_cost: initial_cost2,
              iteration_cost: iteration_cost2
    end

    context 'when lines are parallel' do
      let(:initial_cost1)   { 20 }
      let(:iteration_cost1) { rand 1..100 }

      let(:initial_cost2)   { 45 }
      let(:iteration_cost2) { iteration_cost1 }

      its(:intersection_point) { is_expected.to be_nil }
      its(:intersection_within_boundaries?) { is_expected.to be_falsey }
      its(:intersection_point_within_boundaries) { is_expected.to be_nil }
      its(:intersection_formatted) { is_expected.to eq 'No intersection' }
      its(:difference) { is_expected.to eq(-25) }
      its(:difference_formatted) { is_expected.to eq '-25.00' }
    end

    context 'when 2 lines intersect on an iteration point' do
      let(:initial_cost1)   { 20 }
      let(:iteration_cost1) { 10 }

      let(:initial_cost2)   { 30 }
      let(:iteration_cost2) { 5 }

      its(:intersection_point) { is_expected.to eq [2, 40] }
      its(:intersection_within_boundaries?) { is_expected.to be_truthy }
      its(:intersection_point_within_boundaries) { is_expected.to eq [2, 40] }
      its(:intersection_formatted) { is_expected.to eq '[2.00, 40.00]' }
      its(:difference) { is_expected.to eq 40 }
      its(:difference_formatted) { is_expected.to eq '40.00' }
    end

    context 'when 2 lines intersect between iterations' do
      let(:initial_cost1)   { 20 }
      let(:iteration_cost1) { 10 }

      let(:initial_cost2)   { 30 }
      let(:iteration_cost2) { 6 }

      its(:intersection_point) { is_expected.to eq [2.5, 45] }
      its(:intersection_within_boundaries?) { is_expected.to be_truthy }
      its(:intersection_point_within_boundaries) { is_expected.to eq [2.5, 45] }
      its(:intersection_formatted) { is_expected.to eq '[2.50, 45.00]' }
      its(:difference) { is_expected.to eq 30 }
      its(:difference_formatted) { is_expected.to eq '30.00' }
    end

    context 'when 2 lines intersect out of boundaries' do
      let(:initial_cost1)   { 21 }
      let(:iteration_cost1) { 10 }

      let(:initial_cost2)   { 300 }
      let(:iteration_cost2) { 11 }

      its(:intersection_point) { is_expected.to eq [-279, -2769] }
      its(:intersection_within_boundaries?) { is_expected.to be_falsey }
      its(:intersection_point_within_boundaries) { is_expected.to be_nil }
      its(:intersection_formatted) { is_expected.to eq 'No intersection' }
      its(:difference) { is_expected.to eq(-289) }
      its(:difference_formatted) { is_expected.to eq '-289.00' }
    end
  end
end
