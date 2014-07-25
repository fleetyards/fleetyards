require "erb"

# Remove on Rails 4.1 release
# secrets_source = YAML.load(ERB.new(File.read("#{Rails.root}/config/secrets.yml")).result)
# Secrets ||= AwesomeOpenStruct.new(secrets_source[Rails.env])

settings_source = {}#YAML.load(ERB.new(File.read("#{Rails.root}/config/settings.yml")).result)

DefaultSettings ||= AwesomeOpenStruct.new(settings_source[Rails.env])
Settings ||= AwesomeOpenStruct.new(settings_source[Rails.env])

Fleetyards::Application.config.after_initialize do
  begin
    #Settings.merge Setting.to_h
  rescue Exception => e
    # ignore errors
  end
end
