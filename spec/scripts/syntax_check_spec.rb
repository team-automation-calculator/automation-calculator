require 'stringio'
require 'tempfile'
require_relative '../../scripts/utils/syntax_check'

RSpec.describe SyntaxCheck do
  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  def ruby_file(source)
    Tempfile.create(['syntax_check', '.rb']).tap do |file|
      file.write(source)
      file.close
    end.path
  end

  it 'is 0, and says so, when every file parses', :aggregate_failures do
    expect(described_class.run([ruby_file('x = 1'), ruby_file('def y; end')], out: out, err: err)).to eq(0)
    expect(out.string).to eq("Syntax OK: 2 file(s)\n")
  end

  it 'is 1, naming each file that does not parse', :aggregate_failures do
    good = ruby_file('x = 1')
    bad = ruby_file('def y(')
    expect(described_class.run([good, bad], out: out, err: err)).to eq(1)
    expect(err.string).to end_with("Syntax errors in 1 of 2 file(s): #{bad}\n")
  end
end
