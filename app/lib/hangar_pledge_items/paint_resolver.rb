# frozen_string_literal: true

module HangarPledgeItems
  # The catalogue paints an RSI paint name stands for, resolved the way
  # `PaintsImporter` resolves the same names when it builds the catalogue: split
  # into ship and paint, the ship through its model map, the paint through its
  # name map, then the paint of that name on each of those models. Built from
  # the same rules, so a pledge links to exactly the paints its skin created.
  #
  # Models and paints are read once, so one resolver serves a whole sync or
  # backfill.
  class PaintResolver
    # Hundreds of users pledge the same paint, so each name is resolved once.
    def model_paint_ids(name)
      resolved[name] ||= resolve(name)
    end

    private def resolve(name)
      paint = PaintsImporter.extract_paint(name)
      paint_name = PaintsImporter.paint_mapping(paint[:name])

      Array(PaintsImporter.models_mapping(paint[:model_name])).filter_map do |model_name|
        model_id = model_ids[model_name]

        paint_ids[[model_id, paint_name]] if model_id
      end
    end

    private def resolved
      @resolved ||= {}
    end

    private def model_ids
      @model_ids ||= Model.pluck(:name, :id).to_h
    end

    private def paint_ids
      @paint_ids ||= ModelPaint.pluck(:model_id, :name, :id)
        .to_h { |model_id, name, id| [[model_id, name], id] }
    end
  end
end
