# frozen_string_literal: true

require "thor"
require "rdoc/rdoc"
require "git"

class Changelog < Thor
  include Thor::Actions

  def self.exit_on_failure?
    true
  end

  desc "update", "Update the Changelog"
  def update
    changelog_data = File.read(changelog_file)
    changelog = RDoc::Markdown.parse(changelog_data)

    last_version_index = changelog.parts.find_index do |part|
      part.is_a?(RDoc::Markup::Heading) && part.text.include?(last_version[:name])
    end

    puts changelog.parts.shift(last_version_index)
    puts "---"
    puts changelog.parts
    puts "---"

    commits = git.log.since(last_version[:sha])

    messages = commits.map(&:message)

    puts messages
  end

  desc "entry", "Get Entry from Changelog"
  def entry(tag)
    changelog = File.read("CHANGELOG.md")

    match_string = /\#{2,3} \[#{tag.delete("v")}\]\(\S+(v\S+)...v\S+\) \(\S+\)(.*)/m
    match = changelog.scan(match_string)

    last_tag = match.first&.first&.delete("v")

    raise "No Tag Found!" if last_tag.nil?

    File.write("#{tag}.md", %(
#{match.first.last.scan(/(.*)### \[#{last_tag}/m).first&.first}

### Image
ghcr.io/fleetyards/app:#{tag}
    ))
  end

  no_commands do
    private def git
      @git ||= Git.open("#{__dir__}/../..")
    end

    private def changelog_file
      "CHANGELOG.new.md"
    end

    private def last_version
      last_version_sha = git.tags.last

      {
        name: git.describe(last_version_sha, tags: true),
        sha: last_version_sha
      }
    end
  end
end
