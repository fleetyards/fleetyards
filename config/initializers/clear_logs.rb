# frozen_string_literal: true

if Rails.env.development? || Rails.env.test?
  `rails log:clear`
  `rm -rf #{Rails.root.join('test', 'e2e', 'screenshots', '*')} 2> /dev/null`
end
