#!/usr/bin/env node

// JavaScript version of the ActionCable type generator
// This can be integrated with existing TypeScript tooling

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

class ActionCableTypeGenerator {
  constructor(schemaPath, outputDir) {
    this.schema = yaml.load(fs.readFileSync(schemaPath, 'utf8'));
    this.outputDir = outputDir;
    
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }
  }

  generate() {
    const channels = this.extractChannels();
    
    if (Object.keys(channels).length === 0) {
      console.log('No ActionCable channels found in schema');
      return;
    }

    this.generateChannelTypes(channels);
    this.generateMessageTypes(channels);
    this.generateSubscriptionTypes(channels);
    this.generateClientExample();
    this.generateIndexFile();

    console.log(`✅ Generated ActionCable TypeScript types in ${this.outputDir}`);
  }

  extractChannels() {
    return this.schema['x-actioncable-channels'] || {};
  }

  generateChannelTypes(channels) {
    const types = [
      '// Auto-generated ActionCable channel types',
      `// Generated on ${new Date().toISOString().split('T')[0]}`,
      '',
      'export type ActionCableChannel =',
      ...Object.keys(channels).map((name, i, arr) => 
        `  | '${name}'${i === arr.length - 1 ? ';' : ''}`
      ),
      '',
      'export interface ChannelIdentifier {',
      '  channel: ActionCableChannel;',
      '  [key: string]: any;',
      '}',
      '',
      '// Channel-specific identifiers',
      ...Object.keys(channels).map(name => {
        const channelConfig = channels[name];
        const subscription = channelConfig.subscription || {};
        const baseName = name.replace('Channel', '');
        
        const lines = [
          `export interface ${baseName}ChannelIdentifier extends ChannelIdentifier {`,
          `  channel: '${name}';`,
        ];

        // Add any channel-specific params
        if (subscription.type === 'stream_for' && subscription.resource) {
          lines.push(`  // Automatically includes current_user context`);
        }

        lines.push('}');
        return lines.join('\n');
      }),
    ];

    fs.writeFileSync(
      path.join(this.outputDir, 'channels.ts'),
      types.join('\n')
    );
  }

  generateMessageTypes(channels) {
    const types = [
      '// Auto-generated ActionCable message types',
      "import type { Vehicle, Model } from '../api/types';",
      '',
    ];

    const messageTypes = [];

    Object.entries(channels).forEach(([channelName, channelConfig]) => {
      const broadcasts = channelConfig.broadcasts || {};
      const baseName = channelName.replace('Channel', '');

      if (Object.keys(broadcasts).length > 0) {
        types.push(`// ${channelName} broadcast messages`);

        Object.entries(broadcasts).forEach(([broadcastName, broadcastConfig]) => {
          const typeName = `${baseName}${this.camelize(broadcastName)}Message`;
          
          if (broadcastConfig.schema?.['$ref']) {
            const refType = this.extractRefType(broadcastConfig.schema['$ref']);
            types.push(`export type ${typeName} = ${refType};`);
          } else if (broadcastConfig.schema) {
            types.push(`export interface ${typeName} ${this.generateInterfaceFromSchema(broadcastConfig.schema)}`);
          } else {
            types.push(`export type ${typeName} = any; // No schema defined`);
          }

          messageTypes.push({
            channel: channelName,
            event: broadcastName,
            typeName
          });
        });

        types.push('');
      }
    });

    // Generate discriminated union for all messages
    types.push('// Discriminated union of all broadcast messages');
    types.push('export type ActionCableBroadcast =');
    messageTypes.forEach((msg, i) => {
      const isLast = i === messageTypes.length - 1;
      types.push(`  | { channel: '${msg.channel}'; event: '${msg.event}'; data: ${msg.typeName} }${isLast ? ';' : ''}`);
    });

    types.push('');
    types.push('// WebSocket message wrapper');
    types.push('export interface ActionCableMessage {');
    types.push('  identifier: string;');
    types.push('  message: any;');
    types.push('}');

    fs.writeFileSync(
      path.join(this.outputDir, 'messages.ts'),
      types.join('\n')
    );
  }

  generateSubscriptionTypes(channels) {
    const types = [
      '// Auto-generated ActionCable subscription types',
      "import type { ActionCableChannel, ChannelIdentifier } from './channels';",
      '',
      '// Command types',
      'export interface SubscribeCommand {',
      "  command: 'subscribe';",
      '  identifier: string; // JSON stringified ChannelIdentifier',
      '}',
      '',
      'export interface UnsubscribeCommand {',
      "  command: 'unsubscribe';",
      '  identifier: string;',
      '}',
      '',
      'export interface MessageCommand {',
      "  command: 'message';",
      '  identifier: string;',
      '  data: string; // JSON stringified action data',
      '}',
      '',
      'export type ActionCableCommand = SubscribeCommand | UnsubscribeCommand | MessageCommand;',
      '',
      '// Server responses',
      'export interface ConfirmationMessage {',
      "  type: 'confirm_subscription' | 'reject_subscription';",
      '  identifier: string;',
      '}',
      '',
      'export interface WelcomeMessage {',
      "  type: 'welcome';",
      '}',
      '',
      'export interface PingMessage {',
      "  type: 'ping';",
      '  message: number;',
      '}',
      '',
      'export interface DisconnectMessage {',
      "  type: 'disconnect';",
      '  reason: string;',
      '  reconnect: boolean;',
      '}',
      '',
      'export type ActionCableProtocolMessage =',
      '  | WelcomeMessage',
      '  | ConfirmationMessage',
      '  | PingMessage',
      '  | DisconnectMessage;',
    ];

    fs.writeFileSync(
      path.join(this.outputDir, 'subscriptions.ts'),
      types.join('\n')
    );
  }

  generateClientExample() {
    const example = [
      '// Example ActionCable client usage with TypeScript',
      "import { createConsumer } from '@rails/actioncable';",
      "import type {",
      "  HangarChannelIdentifier,",
      "  HangarVehicleUpdateMessage,",
      "  ActionCableMessage",
      "} from './index';",
      '',
      '// Create ActionCable consumer',
      'const consumer = createConsumer("/cable");',
      '',
      '// Subscribe to HangarChannel',
      'const hangarChannel = consumer.subscriptions.create(',
      '  { channel: "HangarChannel" } as HangarChannelIdentifier,',
      '  {',
      '    connected() {',
      '      console.log("Connected to HangarChannel");',
      '    },',
      '',
      '    disconnected() {',
      '      console.log("Disconnected from HangarChannel");',
      '    },',
      '',
      '    received(data: HangarVehicleUpdateMessage) {',
      '      console.log("Vehicle updated:", data);',
      '      // Handle vehicle update',
      '      if (data.id && data.model) {',
      '        // Update UI with new vehicle data',
      '      }',
      '    }',
      '  }',
      ');',
      '',
      '// Subscribe to ModelsChannel (global)',
      'const modelsChannel = consumer.subscriptions.create(',
      '  { channel: "ModelsChannel" },',
      '  {',
      '    received(data: Model) {',
      '      console.log("Model updated:", data);',
      '    }',
      '  }',
      ');',
      '',
      '// Unsubscribe when done',
      '// hangarChannel.unsubscribe();',
    ];

    fs.writeFileSync(
      path.join(this.outputDir, 'example.ts'),
      example.join('\n')
    );
  }

  generateIndexFile() {
    const index = [
      '// ActionCable TypeScript types',
      "export * from './channels';",
      "export * from './messages';",
      "export * from './subscriptions';",
      '',
      '// Re-export for convenience',
      "export type { Vehicle, Model } from '../api/types';",
    ];

    fs.writeFileSync(
      path.join(this.outputDir, 'index.ts'),
      index.join('\n')
    );
  }

  generateInterfaceFromSchema(schema) {
    const lines = ['{'];
    
    if (schema.properties) {
      Object.entries(schema.properties).forEach(([key, value]) => {
        const isRequired = schema.required?.includes(key);
        const optional = isRequired ? '' : '?';
        lines.push(`  ${key}${optional}: ${this.schemaToTsType(value)};`);
      });
    }
    
    lines.push('}');
    return lines.join('\n');
  }

  schemaToTsType(schema) {
    if (schema['$ref']) {
      return this.extractRefType(schema['$ref']);
    }

    switch (schema.type) {
      case 'string':
        return schema.enum ? schema.enum.map(v => `'${v}'`).join(' | ') : 'string';
      case 'number':
      case 'integer':
        return 'number';
      case 'boolean':
        return 'boolean';
      case 'array':
        return `${this.schemaToTsType(schema.items)}[]`;
      case 'object':
        return this.generateInterfaceFromSchema(schema);
      default:
        return 'any';
    }
  }

  extractRefType(ref) {
    return ref.split('/').pop();
  }

  camelize(str) {
    return str.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase())
              .replace(/^./, char => char.toUpperCase());
  }
}

// Main execution
if (process.argv.length !== 4) {
  console.log('Usage: node generate-actioncable-types.js <schema.yaml> <output-dir>');
  process.exit(1);
}

const [,, schemaPath, outputDir] = process.argv;

if (!fs.existsSync(schemaPath)) {
  console.error(`Error: Schema file not found: ${schemaPath}`);
  process.exit(1);
}

const generator = new ActionCableTypeGenerator(schemaPath, outputDir);
generator.generate();