# frozen_string_literal: true

namespace :invite, path: '', host: Rails.application.secrets[:invite_domain] do
  get ':fleet_slug/:token' => 'base#fleet', as: :fleet
end
