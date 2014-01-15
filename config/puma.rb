port "#{ENV['PORT']}"
directory "#{ENV['APP_DIR']}"
workers 2
activate_control_app "tcp://127.0.0.1:#{ENV["CTRL_PORT"].to_i}", { no_token: true }
