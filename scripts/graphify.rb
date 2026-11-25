# Knowledge graph commands (the graphify rule of repo-standards).
#
# graphify-out/ holds a graph of main. It is gitignored: built once with
# `/graphify .` in the main checkout, on main, and from then on only its code
# layer is refreshed here (AST, seconds). Nothing in this file calls an LLM;
# documents wait for `/graphify --update` in a session.
# `./go graphify-status` is in graphify_status.rb.
require 'open3'

class Graphify
  OUT = 'graphify-out'.freeze
  GRAPH = File.join(OUT, 'graph.json').freeze
  # The interpreter graphify was installed into, recorded by the skill.
  PYTHON_FILE = File.join(OUT, '.graphify_python').freeze
  # HEAD at the last successful refresh. graph.json's built_at_commit does
  # not move when a refresh finds no change, so status reads this first.
  SYNCED_FILE = File.join(OUT, '.graphify_synced_commit').freeze
  SEED_SCRIPT = File.join('scripts', 'graphify', 'graphify_seed.py').freeze
  # Environments thrown away when they end: a graph built there is wasted.
  EPHEMERAL_VARIABLES = %w[CLAUDE_CODE_REMOTE GITHUB_ACTIONS CI].freeze
  SHRINK_REFUSAL = /Refusing to overwrite/

  class << self
    # ./go graphify-update: refresh the code layer to HEAD. Safe unattended
    # (git-sync's post_sync): exits 0 with a note when there is nothing to do.
    def update(_cmds)
      reason = ephemeral_reason || no_graph_reason || off_main_reason
      return note("skipping: #{reason}") if reason

      command = recorded_python || binary_on_path
      abort('graphify: graphify is not installed (pip install graphifyy)') unless command

      refresh(command)
      record_synced_commit
    end

    # ./go graphify-seed [--force] [--no-update] [--quiet]: give a worktree
    # its own copy of the main checkout's graph.
    def seed(cmds)
      exit(1) unless system('python3', SEED_SCRIPT, *cmds)
    end

    def ephemeral_reason(env = ENV)
      name = EPHEMERAL_VARIABLES.find do |variable|
        !['', '0', 'false'].include?(env[variable].to_s.strip.downcase)
      end
      name && "#{name} is set (the graph lives only on a persistent machine)"
    end

    def no_graph_reason
      return if File.file?(GRAPH)
      return "no #{GRAPH} in this worktree (./go graphify-seed copies main's)" unless main_checkout?

      "no #{GRAPH} yet (build it once: /graphify . in this checkout, on main)"
    end

    def note(message)
      puts "graphify: #{message}"
    end

    def git(*args)
      out, status = Open3.capture2('git', *args, err: File::NULL)
      status.success? ? out.strip : nil
    rescue Errno::ENOENT
      nil
    end

    private

    def main_checkout?
      top = git('rev-parse', '--path-format=absolute', '--show-toplevel')
      common = git('rev-parse', '--path-format=absolute', '--git-common-dir')
      return false unless top && common

      File.realpath(File.dirname(common)) == File.realpath(top)
    end

    # The graph is main's: the main checkout never rebuilds it on a branch.
    # A seeded worktree refreshes its own copy on whatever branch it is on.
    def off_main_reason
      return unless main_checkout?

      branch = git('rev-parse', '--abbrev-ref', 'HEAD')
      "the main checkout is on #{branch}, not main (the graph is main's)" unless branch == 'main'
    end

    # launchd's PATH (git-sync) has no pyenv or pipx shim, so the recorded
    # interpreter comes first.
    def recorded_python
      return unless File.file?(PYTHON_FILE)

      python = File.read(PYTHON_FILE).strip
      [python, '-m', 'graphify'] if File.file?(python) && File.executable?(python)
    end

    def binary_on_path
      binary = ENV.fetch('PATH', '').split(File::PATH_SEPARATOR)
                  .map { |dir| File.join(dir, 'graphify') }
                  .find { |path| File.file?(path) && File.executable?(path) }
      binary && [binary]
    end

    def run_update(command, *flags)
      Open3.capture3({ 'GRAPHIFY_NO_TIPS' => '1' }, *command, 'update', '.', *flags)
    end

    # graphify refuses a rebuild with fewer nodes than before. After a merge
    # that deleted or moved code the smaller graph is the correct one.
    def refresh(command)
      out, err, status = run_update(command)
      if !status.success? && SHRINK_REFUSAL.match?(err)
        note('the rebuild has fewer nodes than before; rebuilding with --force')
        out, err, status = run_update(command, '--force')
      end
      print out
      abort("graphify: update failed\n#{err}") unless status.success?
    end

    def record_synced_commit
      head = git('rev-parse', 'HEAD')
      return unless head

      File.write(SYNCED_FILE, "#{head}\n")
      note("code layer refreshed to #{head[0, 7]} (no LLM)")
    end
  end
end
