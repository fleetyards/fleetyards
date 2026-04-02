require "griddler"
require "griddler/postmark/version"
require "griddler/postmark/adapter"

Griddler.adapter_registry.register(:postmark, Griddler::Postmark::Adapter)
