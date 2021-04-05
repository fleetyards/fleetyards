# frozen_string_literal: true

namespace :short, path: '', host: Rails.application.secrets[:short_domain] do
  get 'h/:username' => 'base#hangar', as: :public_hangar
  get 'fi/:token' => 'base#fleet_invite', as: :fleet_invite
end
