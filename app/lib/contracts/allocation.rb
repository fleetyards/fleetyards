# frozen_string_literal: true

module Contracts
  # Which delivered rows count toward which contract line, where several lines
  # ask for the same position -- a part plain and crafted, or crafted at two sets
  # of grades -- and a row may answer more than one of them.
  #
  # A row counts once. Handing rows out greedily makes the answer depend on the
  # order they arrive in, and can leave a line short that the deliveries could
  # have filled: a part answering two lines fills the wrong one, and the part
  # only the other line takes then has nowhere to go. So the rows are spread as
  # a flow -- rows on one side, lines on the other, a row reaching a line only
  # where it answers it -- and the largest flow is what counts: as much of every
  # line filled as the deliveries can fill. Rows and lines are walked in a fixed
  # order, so the same deliveries always land the same way.
  #
  # What no line has room for stays with the first line it answers, as an
  # over-delivery, which is how a single line has always counted it.
  class Allocation
    # @param lines [Array<FleetContractItem>] in contract order
    # @param rows [Array<Hash>] rollup rows carrying `:quantity`
    # @yield [line, row] whether the row answers the line
    def initialize(lines, rows, &answers)
      @lines = lines
      @rows = rows.sort_by { |row| self.class.row_key(row) }
      @answers = answers
    end

    # @return [Hash{String => Array<Hash>}] the rows each line counts, by line id
    def call
      flow = max_flow
      allocated = Hash.new { |hash, id| hash[id] = [] }

      @rows.each_with_index do |row, r|
        left = row[:quantity]

        @lines.each_with_index do |line, l|
          taken = flow[[r, l]]
          next unless taken&.positive?

          allocated[line.id] << row.merge(quantity: taken)
          left -= taken
        end

        next unless left.positive?

        first = @lines.index { |line| @answers.call(line, row) }
        allocated[@lines[first].id] << row.merge(quantity: left) if first
      end

      allocated
    end

    def self.row_key(row)
      [
        row[:inventory_transfer_id].to_s,
        row[:quality].to_i,
        row[:crafted_blueprint_id].to_s,
        (row[:crafted_qualities] || {}).to_a.sort.to_s
      ]
    end

    # Edmonds-Karp over source -> rows -> lines -> sink. The graphs are a
    # contract's worth of lines and a handful of rows each, so the plain
    # augmenting-path search is all it takes.
    private def max_flow
      edges = @rows.each_index.flat_map do |r|
        @lines.each_index.select { |l| @answers.call(@lines[l], @rows[r]) }.map { |l| [r, l] }
      end

      flow = Hash.new(0.to_d)
      row_used = Array.new(@rows.size, 0.to_d)
      line_used = Array.new(@lines.size, 0.to_d)

      loop do
        path = augmenting_path(edges, flow, row_used, line_used)
        break if path.nil?

        amount = bottleneck(path, flow, row_used, line_used)
        apply(path, amount, flow, row_used, line_used)
      end

      flow
    end

    # Breadth-first over the residual graph. A node is [:row, r] or [:line, l];
    # the path runs from a row with spare quantity to a line with spare room.
    private def augmenting_path(edges, flow, row_used, line_used)
      starts = @rows.each_index.select { |r| row_used[r] < @rows[r][:quantity] }
      parents = starts.to_h { |r| [[:row, r], nil] }
      queue = starts.map { |r| [:row, r] }

      until queue.empty?
        node = queue.shift
        kind, index = node

        if kind == :line && line_used[index] < @lines[index].quantity
          return trace(parents, node)
        end

        neighbours =
          if kind == :row
            edges.select { |r, _| r == index }.map { |_, l| [:line, l] }
          else
            edges.select { |r, l| l == index && flow[[r, l]].positive? }.map { |r, _| [:row, r] }
          end

        neighbours.each do |neighbour|
          next if parents.key?(neighbour)

          parents[neighbour] = node
          queue << neighbour
        end
      end

      nil
    end

    private def trace(parents, node)
      path = [node]
      path.unshift(parents[path.first]) while parents[path.first]
      path
    end

    # Forward steps go row to line and are bounded by nothing but the ends;
    # backward steps go line to row and give back flow already sent.
    private def bottleneck(path, flow, row_used, line_used)
      first_row = path.first.last
      last_line = path.last.last

      limits = [@rows[first_row][:quantity] - row_used[first_row], @lines[last_line].quantity - line_used[last_line]]

      path.each_cons(2) do |(from_kind, from), (_, to)|
        limits << flow[[to, from]] if from_kind == :line
      end

      limits.min
    end

    private def apply(path, amount, flow, row_used, line_used)
      row_used[path.first.last] += amount
      line_used[path.last.last] += amount

      path.each_cons(2) do |(from_kind, from), (_, to)|
        if from_kind == :row
          flow[[from, to]] += amount
        else
          flow[[to, from]] -= amount
        end
      end
    end
  end
end
