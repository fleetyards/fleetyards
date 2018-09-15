# frozen_string_literal: true

require 'thor'

class Release < Thor
  include Thor::Actions

  def self.exit_on_failure?
    true
  end

  desc 'new', 'Create new Version'
  option :push, type: :boolean, default: false, aliases: :p
  def new(type, name = '')
    if type == 'major' && name.empty?
      raise Thor::Error, 'Major Releases need a Name'
    end

    bump_version(type, name)

    run('thor release:push') if options[:push]
  end

  desc 'push', 'Push new Version'
  def push
    puts 'Pushing new Version'

    run('git push origin master --tags --no-verify')
    run('git push origin master --no-verify', capture: true) # push your changes to update your local state
  end

  no_commands do
    private def versions(type)
      load version_file

      current_version = Fleetyards::VERSION
      major, minor, patch = current_version.delete('v').split('.').map(&:to_i)
      next_version = case type
                     when 'patch'
                       [major, minor, patch + 1].join('.')
                     when 'minor'
                       [major, minor + 1, 0].join('.')
                     when 'major'
                       [major + 1, 0, 0].join('.')
                     else
                       raise Thor::Error, 'Unknown Release type'
                     end

      [current_version, "v#{next_version}", Fleetyards::CODENAME]
    end

    private def update_version_file(type, next_name)
      current_version, next_version, current_name = versions(type)

      next_name = current_name if next_name.empty?

      content = File.read(version_file)
      File.open(version_file, 'w') do |file|
        new_content = content.gsub(current_version, next_version)
        new_content = new_content.gsub(current_name, next_name)
        file.write(new_content)
      end

      [next_version, next_name]
    end

    private def version_file
      'config/version.rb'
    end

    private def bump_version(type, next_name)
      puts "Create new #{type} Version"

      next_version, name = update_version_file(type, next_name)

      run("git add #{version_file}")
      run("git commit -m 'chore(release): new Version #{next_version} (#{name})'")
      run("git tag #{next_version} -m 'Release #{next_version} (#{name})'")
    end
  end
end
