# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/users", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:user) { users :data }

  before do
    sign_in(user) if user.present?
  end

  path "/users/current" do
    get("My Data") do
      deprecated true
      operationId "DEPRECATEDcurrent"
      tags "Users"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/User"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["username"]).to eq("data")
        end
      end
    end
  end
end
