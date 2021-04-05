# frozen_string_literal: true

namespace :short, path: '', host: Rails.application.secrets[:short_domain] do
  get 'h/:username' => 'base#hangar', as: :public_hangar
  get 'fi/:token' => 'base#fleet', as: :fleet_invite
end
