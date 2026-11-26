require_relative 'support/script_helpers'

RSpec.describe HelpText do
  it 'lists every command with no argument' do
    expect { described_class.help([]) }.to output(/^ build:\n.*^ clean - .*^ validate:/m).to_stdout
  end

  it 'prints one command with its subcommands' do
    expect { described_class.help(['db']) }
      .to output(" db:\n   dev - [Default] Connect to the application's database " \
                 "in the development environment with psql\n").to_stdout
  end

  it 'prints a command without subcommands on one line' do
    expect { described_class.help(['stop']) }.to output(" stop - Stop running docker containers.\n").to_stdout
  end

  it 'warns about an unknown command' do
    expect { described_class.help(['nope']) }.to output(/Unrecognized command: nope/).to_stderr
  end
end
