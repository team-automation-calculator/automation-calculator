require_relative 'support/script_helpers'

RSpec.describe GoCommands do
  def help_for(command)
    HelpText::HELP_HASH.fetch(command).keys.map(&:to_s)
  end

  describe 'help' do
    it 'documents every command' do
      expect(HelpText::HELP_HASH.keys).to match_array(described_class::TABLE.keys - [:help])
    end

    it 'documents every subcommand of start, shell and db' do
      { start: Lifecycle::START_TARGETS, shell: Shell::CONTAINERS, db: DatabaseTerminal::DATABASES }
        .each { |command, table| expect(help_for(command)).to match_array(table.keys.map(&:to_s)) }
    end

    it 'documents the images and flags of build' do
      expect(help_for(:build)).to match_array(DockerImages.new(env: {}).names + DockerBuild::FLAGS)
    end

    it 'documents the images and modes of push' do
      expect(help_for(:push)).to match_array(%w[prod ci base] + DockerHub::PUSH_MODES.keys)
    end

    it 'documents the smoke targets' do
      expect(help_for(:smoke)).to match_array(Verify::SMOKE_TARGETS.keys)
    end

    it 'documents the containers of compile, lint, test and validate' do
      %i[compile lint test validate].each { |command| expect(help_for(command)).to match_array(Verify::CONTAINERS) }
    end
  end

  describe '.run' do
    let(:calls) { [] }
    let(:table) { { init: ->(args) { calls << [:init, args] }, fail: ->(_) { raise CommandFailure, 'nope' } } }

    it 'runs the named command with the arguments after it' do
      described_class.run(%w[init --no-cache], table: table)
      expect(calls).to eq([[:init, ['--no-cache']]])
    end

    it 'runs init when no command is named' do
      described_class.run([], table: table)
      expect(calls).to eq([[:init, []]])
    end

    it 'warns about an unknown command' do
      expect { described_class.run(['nope'], table: table) }.to output(/Unrecognized command: nope/).to_stderr
    end

    it 'prints a failure and exits 1' do
      expect { described_class.run(['fail'], table: table) }
        .to raise_error(an_object_having_attributes(status: 1)).and output("nope\n").to_stderr
    end
  end
end
