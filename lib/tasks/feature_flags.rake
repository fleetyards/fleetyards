# frozen_string_literal: true

namespace :feature_flags do
  desc "Validate config/feature_flags.yml against the registry rules"
  task validate: :environment do
    registry = FeatureFlags::Registry.load
    puts "✓ config/feature_flags.yml is valid (#{registry.names.size} flags)"
  rescue FeatureFlags::Registry::InvalidRegistryError => e
    abort e.message
  end

  desc "Show what feature_flags:sync would change, without touching Flipper"
  task plan: :environment do
    puts FeatureFlags::Synchronizer.new(dry_run: true).call.to_console
  end

  desc "Reconcile Flipper with config/feature_flags.yml (adds + prunes). FEATURE_FLAGS_PRUNE=false disables removal."
  task sync: :environment do
    puts FeatureFlags::Synchronizer.new.call.to_console
  end

  desc "Print a YAML skeleton of the flags currently in Flipper (to bootstrap or reconcile the registry)"
  task export: :environment do
    Flipper.features.map(&:key).sort.each do |name|
      puts <<~YAML
        #{name}:
          description: "TODO"
      YAML
    end
  end
end
