# frozen_string_literal: true

module Locations
  # A system's structure, as the bodies a reader finds their way by: the star,
  # its planets in orbit order, their moons and cities. Everything else under a
  # body is counted by kind rather than listed -- Nyx alone holds 306 outposts
  # called QV Logistics Station.
  #
  # Built from one query over the system rather than one per level.
  class Tree
    STRUCTURAL_KINDS = %w[system star planet moon city].freeze

    LAGRANGE_KEY = /\A[A-Za-z]+\d+_L\d\z/
    GATEWAY_KEY = /\ARR_JP_/

    Node = Struct.new(:location, :counts, :children, :lagrange_points, :gateways)

    def initialize(location)
      @root = location.system || location
    end

    def call
      node(@root)
    end

    private def node(location)
      kids = children_of[location.id].to_a
      lagrange_points, kids = kids.partition { |kid| kid.sc_key.match?(LAGRANGE_KEY) }
      gateways, kids = kids.partition { |kid| kid.sc_key.match?(GATEWAY_KEY) }
      bodies, others = kids.partition { |kid| STRUCTURAL_KINDS.include?(kid.kind) }

      # Lagrange points and gateways are listed, so they are not counted too.
      Node.new(
        location:,
        counts: others.group_by(&:kind).map { |kind, rows| {kind:, count: rows.size} },
        children: bodies.map { |kid| node(kid) },
        lagrange_points:,
        gateways:
      )
    end

    # Ordered by key, which is orbit order: Stanton1 is Hurston, Stanton1b its
    # second moon.
    private def children_of
      @children_of ||= Location.current_version
        .where(system_id: @root.id)
        .includes(:parent, :build, :last_build)
        .order(:sc_key)
        .group_by(&:parent_id)
    end
  end
end
