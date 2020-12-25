# frozen_string_literal: true

require 'graphql/client'
require 'graphql/client/http'

module Rsi
  class ProgressTrackerLoader < ::Rsi::BaseLoader
    HTTP = GraphQL::Client::HTTP.new('https://robertsspaceindustries.com/graphql')

    Schema = GraphQL::Client.load_schema('public/rsi_roadmap_schema.json')

    Client = GraphQL::Client.new(schema: Rsi::ProgressTrackerLoader::Schema, execute: Rsi::ProgressTrackerLoader::HTTP)

    TrackerQuery = Rsi::ProgressTrackerLoader::Client.parse <<-'GRAPHQL'
      query($startDate: String!, $endDate: String!) {
        roadmap(startDate: $startDate, endDate: $endDate) {
          ...Team
          deliverables {
            ...Deliverable
            projects {
              ...Project
              __typename
            }
            timeAllocations {
              ...TimeAllocation
              discipline {
                ...Discipline
                __typename
              }
              __typename
            }
            __typename
          }
          __typename
        }
      }
      fragment Team on Team {
        title
        description
        __typename
      }
      fragment Deliverable on Deliverable {
        title
        description
        startDate
        endDate
        __typename
      }
      fragment Project on Project {
        title
        logo
        __typename
      }
      fragment TimeAllocation on TimeAllocation {
        startDate
        endDate
        __typename
      }
      fragment Discipline on Discipline {
        title
        color
        countMembers
        __typename
      }
    GRAPHQL

    def run
      result = Rsi::ProgressTrackerLoader::Client.query(
        TrackerQuery,
        variables: {
          startDate: (Time.current - 1.year).to_date,
          endDate: (Time.current + 1.year).to_date
        }
      )

      item_ids = []

      result.data.roadmap.each do |team|
        team.deliverables.each do |deliverable|
          key = [team.title, deliverable.title, deliverable.start_date, deliverable.end_date].join('-')
          item = ProgressTrackerItem.find_or_create_by(key: key)

          item.update(
            team: team.title,
            title: deliverable.title,
            description: deliverable.description,
            start_date: deliverable.start_date,
            end_date: deliverable.end_date,
            projects: deliverable.projects.map do |project|
              {
                title: project.title,
                logo: project.logo
              }
            end,
            discipline_counts: deliverable.time_allocations.count,
            time_allocations: deliverable.time_allocations.map do |time_allocation|
              {
                start_date: time_allocation.start_date,
                end_date: time_allocation.end_date,
                title: time_allocation.discipline.title,
                color: time_allocation.discipline.color,
                members: time_allocation.discipline.count_members,
              }
            end,
            model: find_model_for_deliverable(deliverable.title)
          )

          item_ids << item.id
        end
      end

      ProgressTrackerItem.where.not(id: item_ids).pluck(:id)
    end

    private def find_model_for_deliverable(name)
      Model.where('name ILIKE ?', strip_tracker_name(name)).first
    end

    private def strip_tracker_name(name)
      name_mapping(strip_name(name).gsub(/(?:Gold Standard)/, '').strip)
    end

    private def name_mapping(name)
      mapping = {
        'Hercules Starlifter C2' => 'C2 Hercules',
        'Hercules Starlifter M2' => 'M2 Hercules',
        'Hercules Starlifter A2' => 'A2 Hercules',
        'Ares Starfighter Ion' => 'Ares Ion',
        'Ares Starfighter Inferno' => 'Ares Inferno',
        'Nova Tonk' => 'Nova',
        'Retaliator' => 'Retaliator Base',
        'MPUV' => 'MPUV Cargo'
      }

      return mapping[name] if mapping[name].present?

      name
    end
  end
end
