require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  describe '#after_sign_in_path_for' do
    subject(:path) { controller.send(:after_sign_in_path_for, argument) }

    context 'when given a first time user with a scenario' do
      let(:argument) { create :user, sign_in_count: 1 }

      it { is_expected.to eq(automation_scenario_url(argument.automation_scenarios.first)) }
    end

    context 'when given a scope instead of a record' do
      let(:argument) { :user }

      it { is_expected.to eq(root_path) }
    end
  end
end
