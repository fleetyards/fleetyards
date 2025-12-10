#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'json'
require 'fileutils'
require 'active_support/core_ext/string'

class ActionCableTypeGenerator
  attr_reader :schema, :output_dir

  def initialize(schema_path, output_dir)
    @schema = YAML.load_file(schema_path)
    @output_dir = output_dir
    FileUtils.mkdir_p(output_dir)
  end

  def generate!
    channels = extract_channels
    
    if channels.empty?
      puts "No ActionCable channels found in schema"
      return
    end

    generate_channel_types(channels)
    generate_message_types(channels)
    generate_subscription_types(channels)
    generate_helper_types
    generate_index_file

    puts "✅ Generated ActionCable TypeScript types in #{output_dir}"
  end

  private

  def extract_channels
    @schema.dig('x-actioncable-channels') || {}
  end

  def generate_channel_types(channels)
    types = []
    
    types << "// Auto-generated ActionCable channel types"
    types << "// Generated from OpenAPI schema on #{Time.now.strftime('%Y-%m-%d')}"
    types << ""
    types << "export type ActionCableChannel ="
    
    channels.each_key do |channel_name|
      types << "  | '#{channel_name}'"
    end
    types.last << ";"
    
    types << ""
    types << "export interface ChannelIdentifier {"
    types << "  channel: ActionCableChannel;"
    types << "  [key: string]: any;"
    types << "}"

    File.write(File.join(output_dir, 'channels.ts'), types.join("\n"))
  end

  def generate_message_types(channels)
    types = []
    
    types << "// Auto-generated ActionCable message types"
    types << "import { Vehicle, Model } from '../api';"
    types << ""
    
    # Generate broadcast message types for each channel
    channels.each do |channel_name, channel_config|
      broadcasts = channel_config['broadcasts'] || {}
      
      next if broadcasts.empty?
      
      types << "// #{channel_name} broadcasts"
      broadcasts.each do |broadcast_name, broadcast_config|
        type_name = "#{channel_name.gsub('Channel', '')}#{broadcast_name.camelize}Message"
        
        # Handle schema references
        if broadcast_config['schema'] && broadcast_config['schema']['$ref']
          ref_type = extract_ref_type(broadcast_config['schema']['$ref'])
          types << "export type #{type_name} = #{ref_type};"
        else
          types << "export interface #{type_name} {"
          types << "  // Add properties based on schema"
          types << "}"
        end
        types << ""
      end
    end

    # Generate union type for all messages
    types << "export type ActionCableBroadcastMessage ="
    message_types = []
    
    channels.each do |channel_name, channel_config|
      broadcasts = channel_config['broadcasts'] || {}
      broadcasts.each_key do |broadcast_name|
        type_name = "#{channel_name.gsub('Channel', '')}#{broadcast_name.camelize}Message"
        message_types << "  | { channel: '#{channel_name}'; event: '#{broadcast_name}'; data: #{type_name} }"
      end
    end
    
    types.concat(message_types)
    types.last << ";"

    File.write(File.join(output_dir, 'messages.ts'), types.join("\n"))
  end

  def generate_subscription_types(channels)
    types = []
    
    types << "// Auto-generated ActionCable subscription types"
    types << "import { ActionCableChannel, ChannelIdentifier } from './channels';"
    types << ""
    
    types << "export interface SubscribeCommand {"
    types << "  command: 'subscribe';"
    types << "  identifier: string; // JSON stringified ChannelIdentifier"
    types << "}"
    types << ""
    
    types << "export interface UnsubscribeCommand {"
    types << "  command: 'unsubscribe';"
    types << "  identifier: string; // JSON stringified ChannelIdentifier"
    types << "}"
    types << ""
    
    types << "export interface MessageCommand {"
    types << "  command: 'message';"
    types << "  identifier: string;"
    types << "  data: string; // JSON stringified message data"
    types << "}"
    types << ""
    
    types << "export type ActionCableCommand = SubscribeCommand | UnsubscribeCommand | MessageCommand;"
    types << ""
    
    # Generate subscription parameter types for each channel
    channels.each do |channel_name, channel_config|
      next unless channel_config['subscription']
      
      subscription = channel_config['subscription']
      param_type = "#{channel_name.gsub('Channel', '')}ChannelParams"
      
      types << "export interface #{param_type} extends ChannelIdentifier {"
      types << "  channel: '#{channel_name}';"
      
      if subscription['params']
        subscription['params'].each do |param_name, param_config|
          types << "  #{param_name}?: #{typescript_type(param_config)};"
        end
      end
      
      types << "}"
      types << ""
    end

    File.write(File.join(output_dir, 'subscriptions.ts'), types.join("\n"))
  end

  def generate_helper_types
    types = []
    
    types << "// ActionCable helper types and utilities"
    types << "import { SubscribeCommand, UnsubscribeCommand, MessageCommand } from './subscriptions';"
    types << "import { ActionCableBroadcastMessage } from './messages';"
    types << ""
    
    types << "export interface ActionCableConfirmation {"
    types << "  type: 'confirm_subscription' | 'reject_subscription';"
    types << "  identifier: string;"
    types << "}"
    types << ""
    
    types << "export interface ActionCableWelcome {"
    types << "  type: 'welcome';"
    types << "}"
    types << ""
    
    types << "export interface ActionCablePing {"
    types << "  type: 'ping';"
    types << "  message: number;"
    types << "}"
    types << ""
    
    types << "export interface ActionCableDisconnect {"
    types << "  type: 'disconnect';"
    types << "  reason: string;"
    types << "  reconnect: boolean;"
    types << "}"
    types << ""
    
    types << "export type ActionCableMessage ="
    types << "  | ActionCableWelcome"
    types << "  | ActionCableConfirmation"
    types << "  | ActionCablePing"
    types << "  | ActionCableDisconnect"
    types << "  | ActionCableBroadcastMessage;"
    types << ""
    
    # Add helper functions
    types << "// Helper function to create channel identifier"
    types << "export function createChannelIdentifier(params: any): string {"
    types << "  return JSON.stringify(params);"
    types << "}"
    types << ""
    
    types << "// Helper function to parse channel identifier"
    types << "export function parseChannelIdentifier(identifier: string): any {"
    types << "  return JSON.parse(identifier);"
    types << "}"

    File.write(File.join(output_dir, 'helpers.ts'), types.join("\n"))
  end

  def generate_index_file
    index = []
    
    index << "// ActionCable TypeScript types"
    index << "export * from './channels';"
    index << "export * from './messages';"
    index << "export * from './subscriptions';"
    index << "export * from './helpers';"

    File.write(File.join(output_dir, 'index.ts'), index.join("\n"))
  end

  def extract_ref_type(ref)
    # Extract type name from $ref like "#/components/schemas/Vehicle"
    ref.split('/').last
  end

  def typescript_type(schema)
    case schema['type']
    when 'string' then 'string'
    when 'number' then 'number'
    when 'integer' then 'number'
    when 'boolean' then 'boolean'
    when 'array' then "#{typescript_type(schema['items'])}[]"
    when 'object' then 'Record<string, any>'
    else 'any'
    end
  end
end

# Main script execution
if ARGV.length != 2
  puts "Usage: #{$0} <openapi-schema.yaml> <output-directory>"
  exit 1
end

schema_path = ARGV[0]
output_dir = ARGV[1]

unless File.exist?(schema_path)
  puts "Error: Schema file not found: #{schema_path}"
  exit 1
end

generator = ActionCableTypeGenerator.new(schema_path, output_dir)
generator.generate!