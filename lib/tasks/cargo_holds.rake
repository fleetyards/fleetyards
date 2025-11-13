# frozen_string_literal: true

namespace :cargo_holds do
  desc "Migrate cargo_holds from YAML to database tables"
  task migrate: :environment do
    puts "Starting cargo holds migration..."

    migrated_count = 0
    skipped_count = 0
    error_count = 0

    Model.find_each do |model|
      next if model.cargo_holds.blank?

      begin
        # Skip if already migrated
        if model.cargo_holds_db.exists?
          skipped_count += 1
          next
        end

        model.update_cargo_holds_db

        migrated_count += 1
        print "." if (migrated_count % 10).zero?
      rescue => e
        error_count += 1
        puts "\nError migrating model #{model.name} (#{model.id}): #{e.message}"
      end
    end

    puts "\n\nMigration complete!"
    puts "Migrated: #{migrated_count}"
    puts "Skipped (already migrated): #{skipped_count}"
    puts "Errors: #{error_count}"
  end

  desc "Recalculate all container capacities"
  task recalculate: :environment do
    puts "Recalculating container capacities for all cargo holds..."

    CargoHold.count
    processed = 0

    CargoHold.find_each do |hold|
      hold.calculate_container_capacities!
      processed += 1
      print "." if (processed % 10).zero?
    end

    puts "\n\nRecalculation complete! Processed #{processed} cargo holds."
  end

  desc "Force migrate cargo_holds (destroys existing and reimports)"
  task force_migrate: :environment do
    puts "WARNING: This will destroy all existing cargo_holds data and reimport!"
    puts "Press ENTER to continue or Ctrl+C to cancel..."
    $stdin.gets

    puts "Destroying existing cargo holds..."
    CargoHold.destroy_all

    puts "Starting fresh migration..."
    Rake::Task["cargo_holds:migrate"].invoke
  end

  desc "Show cargo hold statistics"
  task stats: :environment do
    puts "\n=== Cargo Hold Statistics ==="
    puts "Total Models: #{Model.count}"
    puts "Models with YAML cargo_holds: #{Model.where.not(cargo_holds: nil).count}"
    puts "Models with DB cargo_holds: #{Model.joins(:cargo_holds_db).distinct.count}"
    puts "Total cargo holds in DB: #{CargoHold.count}"
    puts "Total container capacities: #{CargoHoldContainerCapacity.count}"
    puts "\nContainer size distribution (holds that can fit each size):"

    CargoHoldContainerCapacity::CONTAINER_SIZES.each do |size|
      count = CargoHoldContainerCapacity.where(container_size_scu: size).where("max_quantity > 0").count
      total_capacity = CargoHoldContainerCapacity.where(container_size_scu: size).sum(:max_quantity)
      puts "  #{size} SCU: #{count} holds (total capacity: #{total_capacity} containers)"
    end
  end

  desc "Verify migration accuracy"
  task verify: :environment do
    puts "Verifying migration accuracy..."

    mismatches = []

    Model.joins(:cargo_holds_db).distinct.find_each do |model|
      yaml_holds = model.cargo_holds || []
      db_holds = model.cargo_holds_db.ordered

      if yaml_holds.size != db_holds.size
        mismatches << {model: model.name, issue: "Hold count mismatch: YAML=#{yaml_holds.size}, DB=#{db_holds.size}"}
        next
      end

      yaml_holds.each_with_index do |yaml_hold, index|
        db_hold = db_holds[index]

        yaml_capacity = yaml_hold["capacity"].to_f.round(2)
        db_capacity = db_hold.capacity_scu.to_f.round(2)

        if (yaml_capacity - db_capacity).abs > 0.01
          mismatches << {
            model: model.name,
            hold: index,
            issue: "Capacity mismatch: YAML=#{yaml_capacity}, DB=#{db_capacity}"
          }
        end
      end
    end

    if mismatches.empty?
      puts "\n✓ All migrations verified successfully!"
    else
      puts "\n✗ Found #{mismatches.size} mismatches:"
      mismatches.each do |mismatch|
        puts "  - #{mismatch[:model]}: #{mismatch[:issue]}"
      end
    end
  end

  desc "Compare CargoFinder vs CargoFinderSql results"
  task compare: :environment do
    puts "Comparing CargoFinder (YAML) vs CargoFinderSql (DB) results..."

    test_sets = [
      {8 => 11, 4 => 1},
      {32 => 5},
      {16 => 10, 8 => 5},
      {1 => 100},
      {24 => 3, 16 => 2, 8 => 4}
    ]

    test_sets.each_with_index do |container_set, index|
      puts "\n--- Test Set #{index + 1}: #{container_set.inspect} ---"

      yaml_results = ScData::CargoFinder.find_fitting_models(container_set).map(&:id).sort
      sql_results = ScData::CargoFinderSql.find_fitting_models(container_set).map(&:id).sort

      puts "YAML results: #{yaml_results.size} models"
      puts "SQL results:  #{sql_results.size} models"

      only_in_yaml = yaml_results - sql_results
      only_in_sql = sql_results - yaml_results

      if only_in_yaml.empty? && only_in_sql.empty?
        puts "✓ Results match!"
      else
        puts "✗ Results differ:"
        puts "  Only in YAML: #{only_in_yaml.size} models" unless only_in_yaml.empty?
        puts "  Only in SQL: #{only_in_sql.size} models" unless only_in_sql.empty?
      end
    end
  end
end
