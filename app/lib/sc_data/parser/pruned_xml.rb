module ScData
  module Parser
    # An XML file as a string, minus the named elements and everything in them.
    #
    # Streams, so a file can be far larger than `File.read` or `Hash.from_xml`
    # could take whole: reads above 2 GB fail outright on macOS.
    class PrunedXml < Nokogiri::XML::SAX::Document
      def self.read(file, without:)
        document = new(without)

        File.open(file) do |io|
          Nokogiri::XML::SAX::Parser.new(document).parse_io(io) { |context| context.replace_entities = true }
        end

        raise ArgumentError, "#{file}: #{document.parse_error}" if document.parse_error

        document.xml
      end

      attr_reader :xml, :parse_error

      def initialize(without)
        super()

        @without = without
        @xml = +""
        @text = +""
        @pruned_depth = 0
      end

      def start_element(name, attributes = [])
        if @pruned_depth.positive? || @without.include?(name)
          @pruned_depth += 1
          return
        end

        flush_text
        @xml << "<" << name
        attributes.each { |key, value| @xml << " " << key << "=" << value.encode(xml: :attr) }
        @xml << ">"
      end

      def end_element(name)
        if @pruned_depth.positive?
          @pruned_depth -= 1
          return
        end

        flush_text
        @xml << "</" << name << ">"
      end

      def characters(text)
        @text << text if @pruned_depth.zero?
      end

      # libxml2 stops at an error without raising, which would return the file
      # up to that point as if it were all of it.
      def error(message)
        @parse_error ||= message.strip
      end

      alias_method :cdata_block, :characters

      # Buffered because libxml2 splits text around entities, so one chunk being
      # blank says nothing. A whole blank run is indentation, which around a
      # pruned only child would read back as a string instead of a hash.
      private def flush_text
        @xml << @text.encode(xml: :text) if @text.present?
        @text.clear
      end
    end
  end
end
