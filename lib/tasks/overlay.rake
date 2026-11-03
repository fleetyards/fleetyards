# frozen_string_literal: true

namespace :overlay do
  desc "Write a channel's overlay export to tmp/overlay/<channel>/ (live, ptu)"
  task :export, [:channel] => :environment do |_task, args|
    channel = args[:channel].presence || "live"
    result = Overlay::Export.new(channel).build

    dir = Rails.root.join("tmp/overlay", channel)
    FileUtils.mkdir_p(dir)
    File.binwrite(dir.join(result.file_name), result.items_gzip)
    File.write(dir.join("manifest.json"), JSON.pretty_generate(result.manifest))

    puts "#{dir.join(result.file_name)} (#{result.manifest[:count]} items, sha256 #{result.sha256})"
  end

  desc "Build a channel's overlay export and upload it to the public bucket (live, ptu)"
  task :publish, [:channel] => :environment do |_task, args|
    channel = args[:channel].presence || "live"
    result = Overlay::Export.new(channel).build

    puts "#{channel}: #{Overlay::Publisher.new(channel).publish(result)} #{result.file_name}"
  end
end
