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

    match_string = /### \[#{tag.delete('v')}\]\(\S+(v\S+)...v\S+\) \(\S+\)(.*)/m
    match = changelog.scan(match_string)

    last_tag = match.first.first.delete('v')

    puts match.first.last.scan(/(.*)### \[#{last_tag}/m)
  end
end
