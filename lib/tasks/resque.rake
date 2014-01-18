require 'resque/tasks'

Resque.before_fork do
  ActiveRecord::Base.establish_connection
end
