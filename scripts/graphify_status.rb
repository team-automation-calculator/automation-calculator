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
  DOCUMENT = /\.(md|markdown|txt|rst|apib|pdf|png|jpe?g|gif|webp|svg)\z/i
  NO_GRAPH_EXIT = 1
  STALE_EXIT = 3

  class << self
    def status(cmds)
      brief = cmds.include?('--brief')
      return if brief && Graphify.ephemeral_reason
      return report_no_graph(brief) unless File.file?(Graphify::GRAPH)

      report(brief, [behind_line, pending_line].compact)
    end

    def document?(path)
      DOCUMENT.match?(path)
    end

    # Documents the manifest lists without a semantic hash: graphify clears
    # it when the content changed since the last LLM pass.
    def pending_documents(manifest)
      manifest.select do |path, entry|
        document?(path) && entry.is_a?(Hash) && entry['semantic_hash'].to_s.empty?
      end.keys.sort
    end

    private

    def git(*args)
      Graphify.git(*args)
    end

    def report_no_graph(brief)
      return if brief

      Graphify.note(Graphify.no_graph_reason)
      exit(NO_GRAPH_EXIT)
    end

    def report(brief, lines)
      if lines.empty?
        Graphify.note("current: the graph matches HEAD #{git('rev-parse', '--short', 'HEAD')}") unless brief
      else
        Graphify.note(lines.join('; '))
        exit(STALE_EXIT) unless brief
      end
    end

    def synced_commit
      file = Graphify::SYNCED_FILE
      recorded = File.file?(file) ? File.read(file).strip : ''
      recorded = JSON.parse(File.read(Graphify::GRAPH))['built_at_commit'].to_s if recorded.empty?
      git('rev-parse', '--verify', '--quiet', "#{recorded}^{commit}") unless recorded.empty?
    rescue JSON::ParserError
      nil
    end

    def behind_line
      built = synced_commit
      return 'built from a commit this checkout does not have: run ./go graphify-update' unless built
      return if built == git('rev-parse', 'HEAD')

      changed = git('diff', '--name-only', built, 'HEAD').to_s.split("\n")
      "#{git('rev-list', '--count', "#{built}..HEAD")} commit(s) behind HEAD " \
        "(#{changed.size} file(s) changed, #{changed.count { |path| document?(path) }} " \
        'of them documents): run ./go graphify-update before relying on the graph'
    end

    def pending_line
      pending = pending_documents(JSON.parse(File.read(MANIFEST)))
      return if pending.empty?

      "#{pending.size} document(s) wait for the LLM pass (/graphify --update): " \
        "#{pending.first(5).join(', ')}#{' ...' if pending.size > 5}"
    rescue JSON::ParserError, SystemCallError
      nil
    end
  end
end
