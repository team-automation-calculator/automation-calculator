require_relative 'support/script_helpers'

RSpec.describe Verify do
  include_context 'with ./go collaborators stubbed'

  let(:ls_files) { 'git ls-files -z -- \*.rb \*.rake bin/\* go Gemfile Rakefile config.ru Guardfile' }
  let(:responses) { { ls_files => "go\0Gemfile\0" } }
  let(:dev) { 'docker compose -f docker-compose.yml -f docker-compose.dev.yml' }
  let(:ci) { 'docker compose -f docker-compose.yml -f docker-compose.ci.yml' }
  let(:smoke) { 'run --rm -e SMOKE_TARGET_URL dev rspec spec/smoke/ --tag smoke' }

  before { env_with('SMOKE_TARGET_URL' => nil) }

  def run(command, *args)
    commands_run(responses: responses) { described_class.public_send(command, args) }
  end

  describe '.compile' do
    it 'parses the files it is given in the dev container' do
      expect(run(:compile, 'app/a.rb'))
        .to eq(["#{dev} run --no-deps --rm dev ruby scripts/utils/syntax_check.rb app/a.rb"])
    end

    it 'parses every tracked Ruby file by default, in the container named' do
      expect(run(:compile, 'ci')).to eq(["#{ci} run --no-deps --rm ci ruby scripts/utils/syntax_check.rb go Gemfile"])
    end
  end

  it 'applies the safe autocorrections in dev on format' do
    expect(commands_run { described_class.autoformat }).to eq(["#{dev} run --no-deps --rm dev rubocop --autocorrect"])
  end

  it 'runs the compile check, then RuboCop, on lint' do
    expect(run(:lint)).to eq(["#{dev} run --no-deps --rm dev ruby scripts/utils/syntax_check.rb go Gemfile",
                              "#{dev} run --no-deps --rm dev rubocop"])
  end

  it 'runs lint, then the suite, on validate' do
    expect(run(:validate, 'ci').last).to eq("#{ci} run --rm ci rspec")
  end

  describe '.rspec_test' do
    it 'runs the suite in dev by default' do
      expect(run(:rspec_test)).to eq(["#{dev} run --rm dev rspec"])
    end

    it 'warns about an unknown container and runs nothing', :aggregate_failures do
      expect { expect(run(:rspec_test, 'nope')).to be_empty }.to output(/Unrecognized command: nope/).to_stderr
    end
  end

  describe '.smoke_test' do
    it 'targets the compose dev service by default', :aggregate_failures do
      expect(run(:smoke_test)).to eq(["#{dev} #{smoke}"])
      expect(ENV.fetch('SMOKE_TARGET_URL')).to eq('http://dev:3000')
    end

    it 'keeps an explicit target for dev' do
      env_with('SMOKE_TARGET_URL' => 'http://example.test')
      run(:smoke_test)
      expect(ENV.fetch('SMOKE_TARGET_URL')).to eq('http://example.test')
    end

    it 'targets staging and production by name' do
      { 'staging' => 'https://staging.automation-calculations.io',
        'prod' => 'https://automation-calculations.io' }.each do |name, url|
        run(:smoke_test, name)
        expect(ENV.fetch('SMOKE_TARGET_URL')).to eq(url)
      end
    end

    it 'runs in the ci container, leaving the target to the caller', :aggregate_failures do
      expect(run(:smoke_test, 'ci')).to eq(["#{ci} run --rm -e SMOKE_TARGET_URL ci rspec spec/smoke/ --tag smoke"])
      expect(ENV.fetch('SMOKE_TARGET_URL', nil)).to be_nil
    end

    it 'warns about an unknown target and runs nothing', :aggregate_failures do
      expect { expect(run(:smoke_test, 'nope')).to be_empty }.to output(/Unrecognized command: nope/).to_stderr
    end
  end
end
