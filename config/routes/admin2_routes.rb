# frozen_string_literal: true

namespace :admin2, path: (ENV['ON_SUBDOMAIN'] ? 'admin2' : ''), constraints: ->(req) { ENV['ON_SUBDOMAIN'] || req.subdomain == 'admin2' } do
  # devise_for :admin_users,
  #            singular: :admin_user, path: '', skip: %i[registration],
  #            path_names: {
  #              sign_in: 'login',
  #              sign_out: 'logout',
  #            }

  root to: 'base#dashboard'
end
