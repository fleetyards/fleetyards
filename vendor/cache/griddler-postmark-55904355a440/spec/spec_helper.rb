require 'griddler/testing'
require 'griddler/postmark'
require 'action_dispatch'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.order = 'random'
  config.include Griddler::Testing
end
