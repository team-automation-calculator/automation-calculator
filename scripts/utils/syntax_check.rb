#! /usr/bin/env ruby

# Compile check for `./go compile`: parses every file named on the command
# line without running it, which is what `ruby -c FILE` does, but for many
# files in one process. Prints each syntax error and exits 1 if any file does
# not parse.
module SyntaxCheck
  # The exit status: 0 when every file parses.
  def self.run(files, out: $stdout, err: $stderr)
    failed = files.reject { |file| parses?(file, err) }
    count = files.size
    if failed.empty?
      out.puts "Syntax OK: #{count} file(s)"
      return 0
    end
    err.puts "Syntax errors in #{failed.size} of #{count} file(s): #{failed.join(', ')}"
    1
  end

  def self.parses?(file, err)
    RubyVM::InstructionSequence.compile_file(file)
  rescue SyntaxError => e
    err.puts e.message
    false
  end
end

exit(SyntaxCheck.run(ARGV)) if $PROGRAM_NAME == __FILE__
