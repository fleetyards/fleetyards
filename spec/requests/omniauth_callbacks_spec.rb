# frozen_string_literal: true

require "rails_helper"

RSpec.describe OmniauthCallbacksController, type: :request do
  let(:email) { "oauth@example.com" }
  let(:uid) { "123456" }
  let(:nickname) { "oauthuser" }

  %i[discord twitch google github].each do |provider|
    describe "##{provider}" do
      before do
        mock_omniauth(provider, uid: uid, email: email, nickname: nickname)
      end

      context "when user is not signed in" do
        context "when no existing user or connection" do
          it "creates a new user and signs in" do
            expect {
              post "/users/auth/#{provider}/callback"
            }.to change(User, :count).by(1)
              .and change(OmniauthConnection, :count).by(1)

            expect(response).to have_http_status(:redirect)
          end

          it "creates an omniauth connection with correct attributes" do
            post "/users/auth/#{provider}/callback"

            connection = OmniauthConnection.last

            expect(connection.uid).to eq(uid)
            expect(connection.provider).to eq(provider.to_s)
            expect(connection.user).to eq(User.last)
            expect(connection.auth_payload).to be_present
          end

          it "sets the username from oauth nickname" do
            post "/users/auth/#{provider}/callback"

            expect(User.last.username).to eq(nickname)
          end
        end

        context "when user with matching email exists" do
          let!(:existing_user) { create(:user, email: email) }

          it "signs in the existing user and creates a connection" do
            expect {
              post "/users/auth/#{provider}/callback"
            }.to change(OmniauthConnection, :count).by(1)

            expect(User.count).to eq(1)
            expect(OmniauthConnection.last.user).to eq(existing_user)
          end
        end

        context "when connection already exists" do
          let!(:existing_user) { create(:user) }
          let!(:connection) {
            create(:omniauth_connection, user: existing_user, uid: uid, provider: provider)
          }

          it "signs in the connected user without creating a new connection" do
            expect {
              post "/users/auth/#{provider}/callback"
            }.to change(OmniauthConnection, :count).by(0)

            expect(response).to have_http_status(:redirect)
          end
        end

        context "when username is already taken" do
          before { create(:user, username: nickname) }

          it "redirects with failure message" do
            post "/users/auth/#{provider}/callback"

            expect(response).to have_http_status(:redirect)
            expect(flash[:alert]).to be_present
          end
        end
      end

      context "when user is signed in (connecting account)" do
        let(:user) { create(:user) }

        before { sign_in user }

        it "creates a connection to the current user" do
          expect {
            post "/users/auth/#{provider}/callback"
          }.to change(user.omniauth_connections, :count).by(1)

          connection = OmniauthConnection.last
          expect(connection.user).to eq(user)
          expect(connection.uid).to eq(uid)
          expect(connection.provider).to eq(provider.to_s)
          expect(response).to have_http_status(:redirect)
        end

        context "when provider is already connected" do
          before do
            create(:omniauth_connection, user: user, uid: uid, provider: provider)
          end

          it "redirects with already connected notice" do
            expect {
              post "/users/auth/#{provider}/callback"
            }.to change(OmniauthConnection, :count).by(0)

            expect(response).to have_http_status(:redirect)
            expect(flash[:notice]).to include("already")
          end
        end
      end
    end
  end

  describe "#failure" do
    it "redirects with an alert on authentication failure" do
      OmniAuth.config.mock_auth[:discord] = :invalid_credentials

      get "/users/auth/discord/callback"

      expect(response).to have_http_status(:redirect)
    end
  end
end
