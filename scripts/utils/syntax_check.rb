#! /usr/bin/env ruby

# Compile check for `./go compile`: parses every file named on the command
# line without running it, which is what `ruby -c FILE` does, but for many
# files in one process. Prints each syntax error and exits 1 if any file does
# not parse.
failed = ARGV.reject do |file|
  RubyVM::InstructionSequence.compile_file(file)
rescue SyntaxError => e
  warn e.message
  false
end

if failed.empty?
  puts "Syntax OK: #{ARGV.size} file(s)"
else
  warn "Syntax errors in #{failed.size} of #{ARGV.size} file(s): " \
       "#{failed.join(', ')}"
  exit 1
end
