require_relative 'support/script_helpers'

RSpec.describe GraphifyBinary do
  let(:binary) { described_class.new(python_file: 'graphify-out/.graphify_python', env: { 'PATH' => '/a:/b' }) }

  before do
    allow(File).to receive_messages(file?: false, executable?: true)
  end

  it 'prefers the interpreter the skill recorded' do
    allow(File).to receive(:file?).with('graphify-out/.graphify_python').and_return(true)
    allow(File).to receive(:file?).with('/venv/bin/python').and_return(true)
    allow(File).to receive(:read).with('graphify-out/.graphify_python').and_return("/venv/bin/python\n")
    expect(binary.command).to eq(['/venv/bin/python', '-m', 'graphify'])
  end

  it 'falls back to the first graphify on the PATH' do
    allow(File).to receive(:file?).with('/b/graphify').and_return(true)
    expect(binary.command).to eq(['/b/graphify'])
  end

  it 'is nil when graphify is not installed' do
    expect(binary.command).to be_nil
  end
end
