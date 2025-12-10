# ActionCable TypeScript Types Generation

## Usage

### Ruby Script
```bash
# Make executable
chmod +x scripts/generate-actioncable-types.rb

# Generate types
./scripts/generate-actioncable-types.rb swagger/v1/schema.yaml frontend/types/actioncable
```

### Node.js Script
```bash
# Install dependencies (if not already installed)
npm install js-yaml

# Generate types
node scripts/generate-actioncable-types.js swagger/v1/schema.yaml frontend/types/actioncable
```

### Integration with Existing Build Process

Add to your `package.json`:
```json
{
  "scripts": {
    "generate-actioncable-types": "node scripts/generate-actioncable-types.js swagger/v1/schema.yaml src/types/actioncable"
  }
}
```

Or integrate with the existing schema generation in `bin/generate-schema`:
```bash
#!/usr/bin/env bash

bundle exec rake rswag:specs:swaggerize
yarn generate-api-client
yarn generate-admin-api-client

# Add ActionCable types generation
ruby scripts/generate-actioncable-types.rb swagger/v1/schema.yaml frontend/types/actioncable
```

## Generated Files Structure

```
frontend/types/actioncable/
├── index.ts          # Main entry point
├── channels.ts       # Channel type definitions
├── messages.ts       # Broadcast message types
├── subscriptions.ts  # Subscription command types
└── example.ts        # Usage examples
```

## Example Generated Types

### channels.ts
```typescript
export type ActionCableChannel =
  | 'HangarChannel'
  | 'WishlistChannel'
  | 'ModelsChannel'
  | 'FleetMembersChannel';

export interface HangarChannelIdentifier extends ChannelIdentifier {
  channel: 'HangarChannel';
  // Automatically includes current_user context
}
```

### messages.ts
```typescript
export type HangarVehicleUpdateMessage = Vehicle;

export type ActionCableBroadcast =
  | { channel: 'HangarChannel'; event: 'vehicle_update'; data: Vehicle }
  | { channel: 'HangarDestroyChannel'; event: 'vehicle_destroyed'; data: Vehicle }
  | { channel: 'ModelsChannel'; event: 'model_update'; data: Model };
```

## Using Generated Types

```typescript
import { createConsumer } from '@rails/actioncable';
import type { 
  HangarChannelIdentifier, 
  Vehicle 
} from '@/types/actioncable';

const consumer = createConsumer();

const subscription = consumer.subscriptions.create(
  { channel: 'HangarChannel' } as HangarChannelIdentifier,
  {
    received(vehicle: Vehicle) {
      // TypeScript knows vehicle is of type Vehicle
      console.log(`Vehicle ${vehicle.name} updated`);
    }
  }
);
```

## Benefits

1. **Type Safety**: Full TypeScript support for ActionCable channels
2. **Auto-completion**: IDE support for channel names and message types
3. **Consistency**: Uses same types as REST API (Vehicle, Model, etc.)
4. **Documentation**: Generated types serve as documentation
5. **Maintainability**: Single source of truth in OpenAPI schema