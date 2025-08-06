# frozen_string_literal: true

# Updated swagger_helper.rb with ActionCable support
# Add these lines after requiring rswag/specs in your swagger_helper.rb:

require "rswag/actioncable_extension"
require "rswag/actioncable_helpers"
require "rswag/actioncable_swagger_helper"

# Then update your RSpec configuration to include ActionCable channels loader:
# (Add this to your existing ComponentsLoader setup)

# In the RSpec.configure block, after setting up components_loader:
actioncable_v1_components_loader = ComponentsLoader.new("actioncable/v1")

# Update the components section to include ActionCable schemas:
# components: {
#   parameters: shared_v1_components_loader.parameters.merge(v1_components_loader.parameters),
#   schemas: shared_v1_components_loader.schemas
#     .merge(v1_components_loader.schemas)
#     .merge(actioncable_v1_components_loader.schemas), # Add this line
#   securitySchemes: shared_v1_components_loader.security_schemes.merge(v1_components_loader.security_schemes)
# }.compact