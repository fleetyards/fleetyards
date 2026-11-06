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

        document.xml
      end

      attr_reader :xml

      def initialize(without)
        super()

        @without = without
        @xml = +""
        @pruned_depth = 0
      end

      def start_element(name, attributes = [])
        if @pruned_depth.positive? || @without.include?(name)
          @pruned_depth += 1
          return
        end

        @xml << "<" << name
        attributes.each { |key, value| @xml << " " << key << "=" << value.encode(xml: :attr) }
        @xml << ">"
      end

      def end_element(name)
        if @pruned_depth.positive?
          @pruned_depth -= 1
          return
        end

        @xml << "</" << name << ">"
      end

      def characters(text)
        @xml << text.encode(xml: :text) if @pruned_depth.zero?
      end

      alias_method :cdata_block, :characters
    end
  end
end
