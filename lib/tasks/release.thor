# frozen_string_literal: true

require 'thor'
require 'json'

class Release < Thor
  include Thor::Actions

  def self.exit_on_failure?
    true
  end

  desc 'new', 'Create new Version'
  option :push, type: :boolean, default: false, aliases: :p
  def new(name = nil)
    if name.nil?
      run('yarn run standard-version')
    else
      run('yarn run standard-version --release-as major')
    end

    bump_version(name)

    run('thor release:push') if options[:push]
  end

  desc 'push', 'Push new Version'
  def push
    puts 'Pushing new Version'

    run('git push origin master --tags --no-verify')
    run('git push origin master --no-verify', capture: true) # push your changes to update your local state
  end

  no_commands do
    private def versions
      load version_file
      package_data = JSON.parse(File.read(package_file))

      current_version = Fleetyards::VERSION
      next_version = package_data['version']

      [current_version, "v#{next_version}", Fleetyards::CODENAME]
    end

    private def update_version_file(next_name)
      current_version, next_version, current_name = versions

      next_name = current_name if next_name.nil?

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

    private def changelog_file
      'CHANGELOG.md'
    end

    private def package_file
      'package.json'
    end

    private def bump_version(next_name)
      puts 'Create new Version'

      next_version, name = update_version_file(next_name)

      run("git add #{version_file}")
      run("git add #{changelog_file}")
      run("git add #{package_file}")
      run("git commit -m 'chore(release): new Version #{next_version} (#{name}) [ci skip]' --no-verify")
      run("git tag #{next_version} -m 'Release #{next_version} (#{name})'")
    end
  end
end
