require_relative 'support/script_helpers'

RSpec.describe Verify do
  include_context 'with a recording runner'

  let(:ls_files) { 'git ls-files -z -- \*.rb \*.rake bin/\* go Gemfile Rakefile config.ru Guardfile' }
  let(:outputs) { { ls_files => "go\0Gemfile\0" } }
  let(:env) { {} }
  let(:dev) { 'docker compose -f docker-compose.yml -f docker-compose.dev.yml' }
  let(:ci) { 'docker compose -f docker-compose.yml -f docker-compose.ci.yml' }
  let(:smoke) { 'run --rm -e SMOKE_TARGET_URL dev rspec spec/smoke/ --tag smoke' }

  def run(command, *args)
    described_class.new(runner: runner, env: env).public_send(command, args)
    runner.commands
  end

  def smoke_target_url
    runner.calls.last.env['SMOKE_TARGET_URL']
  end

  describe '#compile' do
    it 'parses the files it is given in the dev container' do
      expect(run(:compile, 'app/a.rb'))
        .to eq(["#{dev} run --no-deps --rm dev ruby scripts/utils/syntax_check.rb app/a.rb"])
    end

    it 'parses every tracked Ruby file by default, in the container named' do
      expect(run(:compile, 'ci')).to eq(["#{ci} run --no-deps --rm ci ruby scripts/utils/syntax_check.rb go Gemfile"])
    end
  end

  it 'applies the safe autocorrections in dev on format' do
    described_class.new(runner: runner).autoformat
    expect(runner.commands).to eq(["#{dev} run --no-deps --rm dev rubocop --autocorrect"])
  end

  it 'runs the compile check, then RuboCop, on lint' do
    expect(run(:lint)).to eq(["#{dev} run --no-deps --rm dev ruby scripts/utils/syntax_check.rb go Gemfile",
                              "#{dev} run --no-deps --rm dev rubocop"])
  end

  it 'runs lint, then the suite, on validate' do
    expect(run(:validate, 'ci').last).to eq("#{ci} run --rm ci rspec")
  end

  describe '#rspec_test' do
    it 'runs the suite in dev by default' do
      expect(run(:rspec_test)).to eq(["#{dev} run --rm dev rspec"])
    end

    it 'warns about an unknown container and runs nothing', :aggregate_failures do
      expect { expect(run(:rspec_test, 'nope')).to be_empty }.to output(/Unrecognized command: nope/).to_stderr
    end
  end

  describe '#smoke_test' do
    it 'targets the compose dev service by default', :aggregate_failures do
      expect(run(:smoke_test)).to eq(["#{dev} #{smoke}"])
      expect(smoke_target_url).to eq('http://dev:3000')
    end

    context 'with SMOKE_TARGET_URL set' do
      let(:env) { { 'SMOKE_TARGET_URL' => 'http://example.test' } }

      it 'keeps it for dev' do
        run(:smoke_test)
        expect(smoke_target_url).to be_nil
      end

      it 'overrides it for a named environment' do
        run(:smoke_test, 'staging')
        expect(smoke_target_url).to eq('https://staging.automation-calculations.io')
      end
    end

    it 'targets production by name' do
      run(:smoke_test, 'prod')
      expect(smoke_target_url).to eq('https://automation-calculations.io')
    end

    it 'runs in the ci container, leaving the target to the caller', :aggregate_failures do
      expect(run(:smoke_test, 'ci')).to eq(["#{ci} run --rm -e SMOKE_TARGET_URL ci rspec spec/smoke/ --tag smoke"])
      expect(smoke_target_url).to be_nil
    end

    it 'warns about an unknown target and runs nothing', :aggregate_failures do
      expect { expect(run(:smoke_test, 'nope')).to be_empty }.to output(/Unrecognized command: nope/).to_stderr
    end
  end
end
