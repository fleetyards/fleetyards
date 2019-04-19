# frozen_string_literal: true

class Audit < Audited::Audit
  belongs_to :roadmap_item, -> { where(audits: { auditable_type: 'RoadmapItem' }).includes(:audits) }, foreign_key: 'auditable_id', inverse_of: :audits
end
