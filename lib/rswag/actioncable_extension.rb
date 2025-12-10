# frozen_string_literal: true

module Rswag
  module ActionCableExtension
    module DSL
      def channel(channel_name, &block)
        metadata[:channel_name] = channel_name
        metadata[:operation_type] = :channel
        context "ActionCable Channel: #{channel_name}" do
          instance_eval(&block)
        end
      end

      def subscription(description, &block)
        metadata[:subscription] = true
        context "subscription: #{description}" do
          let(:channel_metadata) do
            {
              channel: metadata[:channel_name],
              description: description,
              authentication: metadata[:authentication] || 'required'
            }
          end
          instance_eval(&block)
        end
      end

      def broadcast(event_name, &block)
        metadata[:broadcast] = true
        metadata[:event_name] = event_name
        context "broadcast: #{event_name}" do
          instance_eval(&block)
        end
      end

      def stream_from(stream_name, options = {})
        metadata[:stream_from] = stream_name
        metadata[:stream_type] = options[:type] || :global
        metadata[:stream_params] = options[:params] || {}
      end

      def stream_for(resource, options = {})
        metadata[:stream_for] = resource
        metadata[:stream_type] = :user_specific
        metadata[:stream_params] = options[:params] || {}
      end

      def message_schema(schema)
        metadata[:message_schema] = schema
      end

      def authentication(required: true, method: :current_user)
        metadata[:authentication] = {
          required: required,
          method: method
        }
      end

      def example_message(message)
        metadata[:example_message] = message
      end
    end

    module SwaggerGenerator
      def self.generate_channel_schemas(example)
        metadata = example.metadata
        return unless metadata[:channel_name]

        channel_name = metadata[:channel_name]
        
        {
          "x-actioncable-channels" => {
            channel_name => build_channel_definition(metadata, example)
          }
        }
      end

      def self.build_channel_definition(metadata, example)
        definition = {
          "description" => metadata[:description] || "ActionCable channel for #{metadata[:channel_name]}",
          "authentication" => metadata[:authentication] || { "required" => true, "method" => "current_user" }
        }

        # Add subscription info
        if metadata[:stream_from]
          definition["subscription"] = {
            "type" => "stream_from",
            "stream" => metadata[:stream_from],
            "params" => metadata[:stream_params]
          }
        elsif metadata[:stream_for]
          definition["subscription"] = {
            "type" => "stream_for",
            "resource" => metadata[:stream_for].to_s,
            "params" => metadata[:stream_params]
          }
        end

        # Add broadcasts
        broadcasts = collect_broadcasts(example)
        definition["broadcasts"] = broadcasts if broadcasts.any?

        definition
      end

      def self.collect_broadcasts(example)
        broadcasts = {}
        
        example.example_group.examples.each do |ex|
          next unless ex.metadata[:broadcast] && ex.metadata[:event_name]
          
          event_name = ex.metadata[:event_name]
          broadcasts[event_name] = {
            "description" => ex.metadata[:description],
            "schema" => ex.metadata[:message_schema],
            "example" => ex.metadata[:example_message]
          }.compact
        end

        broadcasts
      end
    end

    module SpecsExtension
      def self.prepended(base)
        base.class_eval do
          alias_method :original_run_test!, :run_test!
          
          def run_test!(example, **kwargs)
            # Run original test
            original_run_test!(example, **kwargs)
            
            # Generate ActionCable documentation if applicable
            if example.metadata[:channel_name]
              channel_schemas = Rswag::ActionCableExtension::SwaggerGenerator.generate_channel_schemas(example)
              
              if channel_schemas
                # Merge with swagger_doc
                swagger_doc = kwargs[:swagger_doc]
                swagger_doc.deep_merge!(channel_schemas)
              end
            end
          end
        end
      end
    end
  end
end

# Extend RSpec with ActionCable DSL
RSpec.configure do |config|
  config.extend Rswag::ActionCableExtension::DSL
end

# Prepend to Rswag::Specs to intercept test runs
if defined?(Rswag::Specs::ExampleRunner)
  Rswag::Specs::ExampleRunner.prepend(Rswag::ActionCableExtension::SpecsExtension)
end