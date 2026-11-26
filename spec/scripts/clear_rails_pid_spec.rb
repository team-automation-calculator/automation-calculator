require_relative 'support/script_helpers'

RSpec.describe ClearRailsPid do
  before { allow(File).to receive(:delete) }

  it 'deletes a leftover server pid file' do
    allow(FileTest).to receive(:exist?).with(described_class::PID_PATH).and_return(true)
    described_class.clear_pid_file_if_it_exists
    expect(File).to have_received(:delete).with(described_class::PID_PATH)
  end

  it 'does nothing when there is none' do
    allow(FileTest).to receive(:exist?).with(described_class::PID_PATH).and_return(false)
    described_class.clear_pid_file_if_it_exists
    expect(File).not_to have_received(:delete)
  end
end
