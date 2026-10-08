FactoryBot.define do
  factory :oauth_access_token, class: Oauth::AccessToken do
    application { create(:oauth_application) }
    expires_in { 2.hours }
  end
end
