# Knowledge graph commands (the graphify rule of repo-standards).
#
# graphify-out/ holds a graph of main. It is gitignored: built once with
# `/graphify .` in the main checkout, on main, and from then on only its code
# layer is refreshed here (AST, seconds). Nothing in this file calls an LLM;
# documents wait for `/graphify --update` in a session.
# `./go graphify-status` is in graphify_status.rb.
require './scripts/utils/command_failure'
require './scripts/utils/graphify_binary'
require './scripts/utils/runner'

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
  SHRINK_REFUSAL = /Refusing to overwrite/.freeze

  def initialize(runner: Runner.new, env: ENV)
    @runner = runner
    @env = env
  end

  # ./go graphify-update: refresh the code layer to HEAD. Safe unattended
  # (git-sync's post_sync): a note, not a failure, when there is nothing to do.
  def update(_cmds)
    reason = ephemeral_reason || no_graph_reason || off_main_reason
    return note("skipping: #{reason}") if reason

    refresh(graphify_command)
    record_synced_commit
  end

  # ./go graphify-seed [--force] [--no-update] [--quiet]: give a worktree
  # its own copy of the main checkout's graph. True when the seed succeeds.
  def seed(cmds)
    @runner.run(['python3', SEED_SCRIPT, *cmds])
  end

  def ephemeral_reason
    name = EPHEMERAL_VARIABLES.find do |variable|
      !['', '0', 'false'].include?(@env[variable].to_s.strip.downcase)
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

  # git's stripped output, or nil when it fails or git is missing.
  def git(*args)
    out, _err, status = @runner.capture('git', *args)
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

  def graphify_command
    GraphifyBinary.new(python_file: PYTHON_FILE, env: @env).command ||
      raise(CommandFailure, 'graphify: graphify is not installed (pip install graphifyy)')
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
    raise CommandFailure, "graphify: update failed\n#{err}" unless status.success?
  end

  def run_update(command, *flags)
    @runner.capture(*command, 'update', '.', *flags, env: { 'GRAPHIFY_NO_TIPS' => '1' })
  end

  def record_synced_commit
    head = git('rev-parse', 'HEAD')
    return unless head

    File.write(SYNCED_FILE, "#{head}\n")
    note("code layer refreshed to #{head[0, 7]} (no LLM)")
  end
end
