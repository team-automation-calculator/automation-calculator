require_relative 'support/script_helpers'

# The one class that really reaches the shell, run against harmless commands.
RSpec.describe Runner do
  subject(:runner) { described_class.new }

  describe '#run' do
    it 'is true when the command exits 0' do
      expect(runner.run('true')).to be(true)
    end

    it 'is false when it fails' do
      expect(runner.run('false')).to be(false)
    end

    it 'raises on a failure under check' do
      expect { runner.run('false', check: true) }.to raise_error(RuntimeError)
    end

    it 'adds env to the environment of an argument list run without a shell' do
      expect(runner.run(['sh', '-c', 'test "$GO_SPEC" = yes'], env: { 'GO_SPEC' => 'yes' })).to be(true)
    end
  end

  it 'reads a command\'s standard output' do
    expect(runner.output('echo hi')).to eq("hi\n")
  end

  it 'captures stdout, stderr and status' do
    out, err, status = runner.capture('sh', '-c', 'echo out; echo err >&2; exit 3')
    expect([out, err, status.exitstatus]).to eq(["out\n", "err\n", 3])
  end

  # exec itself would end the spec run, so only this one example stubs it.
  it 'replaces the process with the command' do
    replacing = described_class.new
    allow(replacing).to receive(:exec)
    replacing.replace('bash')
    expect(replacing).to have_received(:exec).with('bash')
  end
end
