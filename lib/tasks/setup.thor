# frozen_string_literal: true

require 'highline/import'

class Setup < Thor
  include Thor::Actions

  # rubocop:disable Metrics/MethodLength
  desc "admin", "Create Admin-User"
  option :email, type: :string, default: nil
  option :username, type: :string, default: nil
  option :password, type: :string, default: nil
  option :password_confirmation, type: :string, default: nil
  def admin
    require "./config/environment"

    email = if options.include?('email')
              options[:email]
            else
              HighLine.ask("E-Mail: ")
            end

    username = if options.include?('username')
                 options[:username]
               else
                 HighLine.ask("Username: ")
               end

    if email.blank?
      puts "E-Mail can't be blank!"
      exit
    end

    password = if options.include?('password')
                 options[:password]
               else
                 HighLine.ask("Password: ") { |q| q.echo = '*' }
               end

    if password.blank?
      puts "Password can't be blank!"
      exit
    end

    password_confirmation = if options.include?('password_confirmation')
                              options[:password_confirmation]
                            else
                              HighLine.ask("Password (again): ") { |q| q.echo = '*' }
                            end

    if password_confirmation != password
      puts "Passwords dont match!"
      exit
    end

    user = User.new(username: username, email: email, password: password, password_confirmation: password_confirmation, admin: true)
    user.skip_confirmation!
    if user.save!
      puts "Admin User created!"
    else
      puts "Could not create Admin-User!"
      user.errors.each do |error, message|
        puts "#{error}: #{message}"
      end
    end
  end

  desc "recreate_images", "Recreate Images"
  def recreate_images
    require "./config/environment"

    Image.find_each do |image|
      begin
        image.name.cache_stored_file!
        image.name.retrieve_from_cache!(image.name.cache_name)
        image.name.recreate_versions!
        image.save!
      # rubocop:disable Lint/RescueWithoutErrorClass
      rescue => e
        puts "ERROR: YourModel: #{ym.id} -> #{e}"
      end
      # rubocop:enable Lint/RescueWithoutErrorClass
    end

    Manufacturer.find_each do |manufacturer|
      begin
        manufacturer.logo.cache_stored_file!
        manufacturer.logo.retrieve_from_cache!(manufacturer.logo.cache_name)
        manufacturer.logo.recreate_versions!
        manufacturer.save!
      # rubocop:disable Lint/RescueWithoutErrorClass
      rescue => e
        puts "ERROR: YourModel: #{ym.id} -> #{e}"
      end
      # rubocop:enable Lint/RescueWithoutErrorClass
    end
  end

  desc "dev_env", "Copy files for local Dev-Enviroment"
  def dev_env
    app_dir = File.join(File.dirname(__FILE__), '..', '..')
    run "mkdir #{app_dir}/files"
    run "cp #{app_dir}/config/database.example.yml #{app_dir}/config/database.yml"
    run "cp #{app_dir}/config/secrets.example.yml #{app_dir}/config/secrets.yml"
    run "cp #{app_dir}/config/settings.example.yml #{app_dir}/config/settings.yml"
  end
end
