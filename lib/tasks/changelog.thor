# frozen_string_literal: true

require 'thor'

class Changelog < Thor
  include Thor::Actions

  def self.exit_on_failure?
    true
  end

  desc 'entry', 'Get Entry from Changelog'
  def entry(tag)
    changelog = File.read('CHANGELOG.md')

    match_string = /\#{2,3} \[#{tag.delete('v')}\]\(\S+(v\S+)...v\S+\) \(\S+\)(.*)/m
    match = changelog.scan(match_string)

    last_tag = match.first&.first&.delete('v')

    raise 'No Tag Found!' if last_tag.nil?

    File.write("#{tag}.md", %(
#{match.first.last.scan(/(.*)### \[#{last_tag}/m).first&.first}

### Image
ghcr.io/fleetyards/app:#{tag}
    ))
  end
end
