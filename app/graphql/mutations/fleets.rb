# encoding: utf-8
# frozen_string_literal: true

module Mutations
  Fleets = GraphQL::ObjectType.define do
    field :createFleet do
      type Types::FleetType
      description 'Create a New Fleet'
      argument :sid, !types.String
      needs_authentication true
      resolve Resolvers::Fleets::Create.new
    end
    field :destroyFleet do
      type Types::FleetType
      description 'Destroy Fleet'
      argument :sid, !types.String
      needs_authentication true
      resolve Resolvers::Fleets::Destroy.new
    end
    field :joinFleet do
      type !types.Boolean
      description 'Join Fleet'
      argument :sid, !types.String
      needs_authentication true
      resolve Resolvers::Fleets::Join.new
    end
    field :acceptFleetJoin do
      type !types.Boolean
      description 'Accept Fleet Join'
      argument :sid, !types.String
      argument :username, !types.String
      needs_authentication true
      resolve Resolvers::Fleets::AcceptJoin.new
    end
    field :declineFleetJoin do
      type !types.Boolean
      description 'Decline Fleet Join'
      argument :sid, !types.String
      argument :username, !types.String
      needs_authentication true
      resolve Resolvers::Fleets::DeclineJoin.new
    end
    field :promoteFleetMember do
      type !types.Boolean
      description 'Promote Fleet Member'
      argument :sid, !types.String
      argument :username, !types.String
      needs_authentication true
      resolve Resolvers::Fleets::PromoteMember.new
    end
    field :demoteFleetMember do
      type !types.Boolean
      description 'Demote Fleet Member'
      argument :sid, !types.String
      argument :username, !types.String
      needs_authentication true
      resolve Resolvers::Fleets::DemoteMember.new
    end
    field :removeFleetMember do
      type !types.Boolean
      description 'Demote Fleet Member'
      argument :sid, !types.String
      argument :username, !types.String
      needs_authentication true
      resolve Resolvers::Fleets::RemoveMember.new
    end
    # field :inviteToFleet do
    #   type Types::ResultType
    #   description 'Invite to Fleet'
    #   argument :sid, !types.String
    #   argument :username, !types.String
    #   needs_authentication true
    #   resolve Resolvers::Fleets::Invite.new
    # end
    # field :acceptFleetInvitation do
    #   type Types::ResultType
    #   description 'Accept Fleet Invitation'
    #   argument :sid, !types.String
    #   argument :username, !types.String
    #   needs_authentication true
    #   resolve Resolvers::Fleets::AcceptInvite.new
    # end
  end
end
