require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../../scripts/rubocop/shell_boundary'

RSpec.describe RuboCop::Cop::Scripts::ShellBoundary, :config do
  let(:msg) { described_class::MSG }

  it 'flags system' do
    expect_offense(<<~RUBY)
      system('docker compose up')
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
    RUBY
  end

  it 'flags exec and spawn on Kernel and Process' do
    expect_offense(<<~RUBY)
      Kernel.exec('bash') || Process.spawn('ls')
      ^^^^^^^^^^^^^^^^^^^ #{msg}
                             ^^^^^^^^^^^^^^^^^^^ #{msg}
    RUBY
  end

  it 'flags backticks' do
    expect_offense(<<~RUBY)
      `id -u`
      ^^^^^^^ #{msg}
    RUBY
  end

  it 'flags %x' do
    expect_offense(<<~RUBY)
      %x(git rev-parse HEAD)
      ^^^^^^^^^^^^^^^^^^^^^^ #{msg}
    RUBY
  end

  it 'flags Open3' do
    expect_offense(<<~RUBY)
      Open3.capture3('git', 'status')
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
    RUBY
  end

  it 'accepts a runner that was passed in' do
    expect_no_offenses(<<~RUBY)
      @runner.run('docker compose up')
      runner.capture('git', 'status')
      Foo::Open3.capture3('x')
    RUBY
  end
end
