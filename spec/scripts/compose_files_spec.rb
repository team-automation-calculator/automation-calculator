require_relative 'support/script_helpers'

RSpec.describe ComposeFiles do
  it 'joins the base file and the environment file' do
    allow(File).to receive(:exist?).with('docker-compose.local.yml').and_return(false)
    expect(described_class.flags('ci')).to eq('-f docker-compose.yml -f docker-compose.ci.yml')
  end

  it 'appends the untracked local override last when it exists' do
    allow(File).to receive(:exist?).with('docker-compose.local.yml').and_return(true)
    expect(described_class.files('dev')).to eq(%w[docker-compose.yml docker-compose.dev.yml docker-compose.local.yml])
  end
end
