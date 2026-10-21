# frozen_string_literal: true

module ScData
  # Attaches the loading screens each export carries to the builds the site
  # knows about: the configured ones and every build with catalogue rows.
  #
  # An export is immutable once uploaded, so a screen whose ETag is already
  # stored is not fetched again. The ETag is kept as the bucket reports it: the
  # screens are large enough to go up in parts, and a multipart ETag is no MD5
  # that ActiveStorage's checksum could be compared against.
  #
  # Screens of a build that is neither configured nor recorded any more go
  # with it, so retention pruning a build also frees its images.
  class LoadingScreensImportJob < ApplicationJob
    sidekiq_options queue: "loaders"

    def perform
      return unless ::ScData::RawStore.configured?

      builds = builds_to_import

      LoadingScreen.where.not(version: builds.map(&:version)).find_each(&:destroy!)

      builds.each do |build|
        import(build)
      rescue => e
        log(:error, "#{build.version} failed: #{e.class}: #{e.message}")
        Appsignal.report_error(e)
      end
    end

    private def builds_to_import
      (::ScData::Source.configured + ::ScData::Source.recorded).uniq
    end

    private def import(build)
      store = ::ScData::RawStore.new(build.version)
      existing = LoadingScreen.with_attached_image.where(version: build.version).index_by(&:name)

      store.loading_screens.each do |name, object|
        screen = existing[name] || LoadingScreen.new(environment: build.environment, version: build.version, name:)

        next if screen.etag == object.etag && screen.image.attached?

        file = store.fetch(name)

        begin
          # Uploaded before it is attached, so a worker killed in between leaves
          # an unattached blob rather than an attachment naming missing bytes.
          screen.image = ActiveStorage::Blob.create_and_upload!(io: file, filename: name)
          screen.etag = object.etag
          screen.save!
        ensure
          file.close!
        end

        log(:info, "attached #{build.version}/#{name}")
      end
    end

    private def log(level, message)
      Rails.logger.public_send(level, "[sc_data] LoadingScreensImportJob #{message}")
    end
  end
end
