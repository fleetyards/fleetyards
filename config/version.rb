# frozen_string_literal: true

require "yaml"

module Fleetyards
  CODENAME = YAML.load_file(File.expand_path("release.yml", __dir__)).fetch("codename").freeze
  VERSION = "v7.9.0" # x-release-please-version
end
