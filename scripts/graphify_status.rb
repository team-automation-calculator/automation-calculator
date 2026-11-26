# ./go graphify-status [--brief]: how far the knowledge graph is behind HEAD,
# and which documents wait for the LLM pass. Read-only; see graphify.rb.
#
# --brief prints one line when there is something to do and nothing otherwise,
# and always exits 0 (the SessionStart hook). Without it: exit 0 current,
# 3 behind, 1 no graph.
require 'json'
require './scripts/graphify'

class GraphifyStatus
  MANIFEST = File.join(Graphify::OUT, 'manifest.json').freeze
  DOCUMENT = /\.(md|markdown|txt|rst|apib|pdf|png|jpe?g|gif|webp|svg)\z/i.freeze
  NO_GRAPH_EXIT = 1
  STALE_EXIT = 3

  def self.document?(path)
    DOCUMENT.match?(path)
  end

  # Documents the manifest lists without a semantic hash: graphify clears
  # it when the content changed since the last LLM pass.
  def self.pending_documents(manifest)
    manifest.select do |path, entry|
      document?(path) && entry.is_a?(Hash) && entry['semantic_hash'].to_s.empty?
    end.keys.sort
  end

  def initialize(graphify: Graphify.new)
    @graphify = graphify
  end

  # The exit status: see the top of this file.
  def status(cmds)
    cmds.include?('--brief') ? brief_status : full_status
  end

  private

  def brief_status
    return 0 if @graphify.ephemeral_reason || !File.file?(Graphify::GRAPH)

    lines = stale_lines
    @graphify.note(lines.join('; ')) unless lines.empty?
    0
  end

  def full_status
    unless File.file?(Graphify::GRAPH)
      @graphify.note(@graphify.no_graph_reason)
      return NO_GRAPH_EXIT
    end
    lines = stale_lines
    return current_status if lines.empty?

    @graphify.note(lines.join('; '))
    STALE_EXIT
  end

  def current_status
    @graphify.note("current: the graph matches HEAD #{git('rev-parse', '--short', 'HEAD')}")
    0
  end

  def stale_lines
    [behind_line, pending_line].compact
  end

  def git(*args)
    @graphify.git(*args)
  end

  def synced_commit
    recorded = recorded_commit
    git('rev-parse', '--verify', '--quiet', "#{recorded}^{commit}") unless recorded.empty?
  end

  # The commit the last refresh recorded, else the one graph.json was built at.
  def recorded_commit
    file = Graphify::SYNCED_FILE
    recorded = File.file?(file) ? File.read(file).strip : ''
    return recorded unless recorded.empty?

    JSON.parse(File.read(Graphify::GRAPH))['built_at_commit'].to_s
  rescue JSON::ParserError
    ''
  end

  def behind_line
    built = synced_commit
    return 'built from a commit this checkout does not have: run ./go graphify-update' unless built
    return if built == git('rev-parse', 'HEAD')

    changed = git('diff', '--name-only', built, 'HEAD').to_s.split("\n")
    "#{git('rev-list', '--count', "#{built}..HEAD")} commit(s) behind HEAD " \
      "(#{changed.size} file(s) changed, #{changed.count { |path| self.class.document?(path) }} " \
      'of them documents): run ./go graphify-update before relying on the graph'
  end

  def pending_line
    pending = self.class.pending_documents(JSON.parse(File.read(MANIFEST)))
    return if pending.empty?

    count = pending.size
    "#{count} document(s) wait for the LLM pass (/graphify --update): " \
      "#{pending.first(5).join(', ')}#{' ...' if count > 5}"
  rescue JSON::ParserError, SystemCallError
    nil
  end
end
