require_relative 'support/script_helpers'

RSpec.describe EnvironmentVariables do
  include ScriptHelpers

  it 'sets the mock production variables that are missing' do
    env_with('DOCKER_REPO_USER' => nil)
    described_class.set_mock_production_vars
    expect(ENV.fetch('DOCKER_REPO_USER')).to eq('automationcalculator')
  end

  it 'keeps a variable that is already set', :aggregate_failures do
    env_with('DOCKER_REPO_USER' => 'real')
    expect { described_class.set_mock_production_vars }.to output(/DOCKER_REPO_USER has already been set/).to_stdout
    expect(ENV.fetch('DOCKER_REPO_USER')).to eq('real')
  end
end
