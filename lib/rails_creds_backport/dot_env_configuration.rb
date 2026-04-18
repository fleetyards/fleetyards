# frozen_string_literal: true

module RailsCredsBackport
  # Reads a .env file and exposes its values via the same require/option API.
  # Supports quoted values, variable interpolation (${VAR}), and command execution ($(cmd)).
  #
  # REMOVAL: Delete when upgrading to Rails 8.2 (ActiveSupport::DotEnvConfiguration).
  class DotEnvConfiguration < EnvConfiguration
    def initialize(path)
      @path = path
      reload
    end

    def reload
      @envs = parse_env_file
    end

    private

    def parse_env_file
      return {} unless File.exist?(@path.to_s)

      envs = {}

      File.foreach(@path) do |line|
        line = line.strip
        next if line.empty? || line.start_with?("#")

        if line =~ /\A([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\z/
          key, value = $1, $2
          envs[key] = interpolate(execute_commands(unquote(value)), envs)
        end
      end

      envs
    end

    def unquote(value)
      if value.start_with?('"') && value.end_with?('"')
        value[1..-2].gsub('\n', "\n").gsub('\"', '"')
      elsif value.start_with?("'") && value.end_with?("'")
        value[1..-2]
      else
        value
      end
    end

    def execute_commands(value)
      value.gsub(/\$\((.+?)\)/) { `#{$1}`.chomp }
    end

    def interpolate(value, envs)
      value.gsub(/\$\{([A-Za-z_][A-Za-z0-9_]*)\}/) { envs[$1] || "" }
    end
  end
end
