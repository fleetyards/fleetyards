# frozen_string_literal: true

# A record holding a character file as `chf`, resolved against the imported
# customizer export and kept in `resolved`, refreshed whenever the catalogue,
# a face library or a baked tone changes.
module ResolvedCharacterFile
  extend ActiveSupport::Concern

  # The resolved character with every asset served, or nil until the export
  # is imported. A file or export the resolver cannot read leaves it nil too:
  # the file itself is still there to hand out, and the failure is kept for
  # that export so it is neither retried nor reported on every request. A
  # download that fails is tried again next time.
  def character(context = Chf::Context.current)
    return if context.nil? || !chf.attached? || !context.body?(character_body_key)

    if resolved_digest != context.digest
      bytes = chf.download unless @parsed_chf
      spec = resolve(context, bytes)
      update_columns(resolved: spec, resolved_digest: context.digest) if persisted?
      self.resolved = spec
      self.resolved_digest = context.digest
    end

    context.served(resolved) if resolved
  rescue => e
    report_unresolved(e)
    nil
  end

  private def resolve(context, bytes)
    context.resolve(@parsed_chf || Chf::Reader.read(bytes))
  rescue => e
    report_unresolved(e)
    nil
  end

  private def report_unresolved(error)
    Rails.logger.error("[chf] #{self.class.name} #{id} could not be resolved: #{error.class}: #{error.message}")
    Appsignal.report_error(error)
  end
end
