# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Users::OmniauthCallbacksController < ::Devise::OmniauthCallbacksController
  include SlugHelper

  def github
    oauth_data = {
      provider: request.env["omniauth.auth"][:provider],
      uid: request.env["omniauth.auth"][:uid],
      email: request.env["omniauth.auth"][:info][:email],
      username: request.env["omniauth.auth"][:info][:nickname]
    }
    @user = User.from_omniauth(oauth_data)

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "Github") if is_navigational_format?
    else
      session["devise.oauth_data"] = oauth_data
      redirect_to new_user_registration_url
    end
  end

  def google_oauth2
    oauth_data = {
      provider: request.env["omniauth.auth"][:provider],
      uid: request.env["omniauth.auth"][:uid],
      email: request.env["omniauth.auth"][:info][:email],
      username: SlugHelper.generate_slug(request.env["omniauth.auth"][:info][:name])
    }
    @user = User.from_omniauth(oauth_data)

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
    else
      session["devise.oauth_data"] = oauth_data
      redirect_to new_user_registration_url
    end
  end

  def twitter
    oauth_data = {
      provider: request.env["omniauth.auth"][:provider],
      uid: request.env["omniauth.auth"][:uid],
      username: request.env["omniauth.auth"][:info][:nickname]
    }
    @user = User.from_omniauth(oauth_data)

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "Twitter") if is_navigational_format?
    else
      session["devise.oauth_data"] = oauth_data
      redirect_to new_user_registration_url
    end
  end

  def facebook
    oauth_data = {
      provider: request.env["omniauth.auth"][:provider],
      uid: request.env["omniauth.auth"][:uid],
      email: request.env["omniauth.auth"][:info][:email],
      username: SlugHelper.generate_slug(request.env["omniauth.auth"][:info][:name])
    }
    @user = User.from_omniauth(oauth_data)

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "Facebook") if is_navigational_format?
    else
      session["devise.oauth_data"] = oauth_data
      redirect_to new_user_registration_url
    end
  end

  def failure
    redirect_to root_path
  end
end
