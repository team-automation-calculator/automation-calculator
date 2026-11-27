require_relative 'support/script_helpers'

RSpec.describe TrackedEnvFiles do
  def check(*tracked)
    runner = RecordingRunner.new(outputs: { 'git ls-files -z' => tracked.map { |path| "#{path}\0" }.join })
    described_class.new(runner: runner).check
  end

  it 'passes when git tracks no environment file' do
    expect { check('go', 'config/settings.yml', 'app/models/environment.rb') }.not_to raise_error
  end

  it 'allows .env.example, wherever it is' do
    expect { check('.env.example', 'config/.env.example') }.not_to raise_error
  end

  it 'names every tracked environment file, at any depth' do
    expect { check('go', '.env', 'config/.env.production', '.env.example') }
      .to raise_error(CommandFailure, %r{tracked by git: \.env, config/\.env\.production\n.*git rm --cached})
  end

  it 'does not mistake a file that only starts with .env for one' do
    expect { check('.envrc', 'foo.env') }.not_to raise_error
  end
end
