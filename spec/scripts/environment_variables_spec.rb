require_relative 'support/script_helpers'

RSpec.describe EnvironmentVariables do
  describe '.missing_production_vars' do
    it 'returns every mock the environment lacks' do
      expect(described_class.missing_production_vars({}).keys).to eq(described_class::PRODUCTION_VARS.keys)
    end

    it 'keeps a variable that is already set, and says so', :aggregate_failures do
      missing = nil
      expect { missing = described_class.missing_production_vars('DOCKER_REPO_USER' => 'real') }
        .to output("DOCKER_REPO_USER has already been set, not using mock for it.\n").to_stdout
      expect(missing).not_to have_key('DOCKER_REPO_USER')
    end
  end
end
