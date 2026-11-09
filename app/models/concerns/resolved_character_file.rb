# frozen_string_literal: true

# A record holding a character file as `chf`, resolved against the imported
# customizer export and kept in `resolved`, refreshed whenever the catalogue,
# a face library or a baked tone changes.
module ResolvedCharacterFile
  extend ActiveSupport::Concern

  # The resolved character with every asset served, or nil until the export
  # is imported. An export the resolver cannot read leaves it nil too: the
  # file itself is still there to hand out.
  def character(context = Chf::Context.current)
    return if context.nil? || !chf.attached? || !context.body?(character_body_key)

    if resolved_digest != context.digest || resolved.nil?
      spec = context.resolve(parsed_chf)
      update_columns(resolved: spec, resolved_digest: context.digest) if persisted?
      self.resolved = spec
      self.resolved_digest = context.digest
    end

    context.served(resolved)
  rescue => e
    Rails.logger.error("[chf] #{self.class.name} #{id} could not be resolved: #{e.class}: #{e.message}")
    Appsignal.report_error(e)
    nil
  end

  private def parsed_chf
    @parsed_chf ||= Chf::Reader.read(chf.download)
  end
end
