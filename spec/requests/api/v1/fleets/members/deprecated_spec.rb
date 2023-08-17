# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/members", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:fleet) { fleets :starfleet }

  let(:user) { nil }

  let(:fleetSlug) { fleet.slug }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/members/current" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("My Fleet Membership -> use GET /fleets/{fleetSlug}/membership") do
      deprecated true
      operationId "DEPRECATEDfleetMembership"
      tags "FleetMembers"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetMemberMinimal"

        let(:user) { users :data }

        run_test!
      end
    end
  end

  path "/fleets/{fleetSlug}/members/{username}/accept-request" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"
    parameter name: "username", in: :path, type: :string, description: "Username"

    let(:user) { users :jeanluc }

    let(:member) { users :crusher }
    let(:username) { member.username }

    put("Accept Member -> use GET /fleets/{fleetSlug}/members/{username}/accept") do
      deprecated true
      operationId "DEPRECATEDacceptMember"
      tags "FleetMembers"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        run_test!
      end
    end
  end

  path "/fleets/{fleetSlug}/members/{username}/decline-request" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"
    parameter name: "username", in: :path, type: :string, description: "Username"

    let(:user) { users :jeanluc }

    let(:member) { users :will }
    let(:username) { member.username }

    put("Decline Member -> use GET /fleets/{fleetSlug}/members/{username}/decline") do
      deprecated true
      operationId "DEPRECATEDdeclineMember"
      tags "FleetMembers"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        run_test!
      end
    end
  end

  path "/fleets/{fleetSlug}/members/accept-invite" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    put("Accept Membership -> use GET /fleets/{fleetSlug}/membership/accept") do
      deprecated true
      operationId "DEPRECATEDacceptMembership"
      tags "FleetMembers"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        let(:user) { users :will }

        run_test!
      end
    end
  end

  path "/fleets/{fleetSlug}/members/decline-invite" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    put("Decline Membership -> use GET /fleets/{fleetSlug}/membership/decline") do
      deprecated true
      operationId "DEPRECATEDdeclineMembership"
      tags "FleetMembers"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        let(:user) { users :will }

        run_test!
      end
    end
  end

  path "/fleets/{fleetSlug}/members" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    put("Update Membership -> use PUT /fleets/{fleetSlug}/membership") do
      deprecated true
      operationId "DEPRECATEDupdateMembership"
      tags "FleetMembers"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/FleetMembershipUpdateInput"}, required: true

      let(:input) do
        {
          primary: true
        }
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetMember"

        let(:user) { users :jeanluc }

        run_test!
      end
    end
  end

  path "/fleets/{fleetSlug}/members/leave" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    delete("Leave Fleet -> use DELETE /fleets/{fleetSlug}/membership") do
      deprecated true
      operationId "DEPRECATEDleaveFleet"
      tags "FleetMembers"
      produces "application/json"

      response(204, "successful") do
        let(:user) { users :data }

        run_test!
      end
    end
  end
end
