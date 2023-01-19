# frozen_string_literal: true

require "highline/import"

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

    email = if options.include?("email")
              options[:email]
            else
              HighLine.ask("Email: ")
            end

    username = if options.include?("username")
                 options[:username]
               else
                 HighLine.ask("Username: ")
               end

    if email.blank?
      puts "Email can't be blank!"
      exit
    end

    password = if options.include?("password")
                 options[:password]
               else
                 HighLine.ask("Password: ") { |q| q.echo = "*" }
               end

    if password.blank?
      puts "Password can't be blank!"
      exit
    end

    password_confirmation = if options.include?("password_confirmation")
                              options[:password_confirmation]
                            else
                              HighLine.ask("Password (again): ") { |q| q.echo = "*" }
                            end

    if password_confirmation != password
      puts "Passwords dont match!"
      exit
    end

    admin_user = AdminUser.new(username:, email:, password:, password_confirmation:)

    if admin_user.save!
      puts "Admin User created!"
    else
      puts "Could not create Admin-User!"
      admin_user.errors.each do |error, message|
        puts "#{error}: #{message}"
      end
    end
  end

  desc "recreate_images", "Recreate Images"
  def recreate_images
    require "./config/environment"

    Image.find_each do |image|
      image.name.cache_stored_file!
      image.name.retrieve_from_cache!(image.name.cache_name)
      image.name.recreate_versions!
      image.save!
    rescue StandardError => e
      puts "ERROR: YourModel: #{ym.id} -> #{e}"
    end

    Manufacturer.find_each do |manufacturer|
      manufacturer.logo.cache_stored_file!
      manufacturer.logo.retrieve_from_cache!(manufacturer.logo.cache_name)
      manufacturer.logo.recreate_versions!
      manufacturer.save!
    rescue StandardError => e
      puts "ERROR: YourModel: #{ym.id} -> #{e}"
    end
  end
end
# rubocop:enable Metrics/MethodLength
