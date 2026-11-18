module Rsi
  class PledgeStoreLoader < ::Rsi::BaseLoader
    # `ccu_target_seen_at` only ever moves with `ccu_on_sale`, so it says nothing
    # the other does not. The SKU ids are what a cart needs, not anything an
    # admin reads.
    UNREPORTED_COLUMNS = %w[updated_at ccu_target_seen_at rsi_standalone_sku_id rsi_upgrade_sku_id].freeze
    STANDALONE_CATEGORY = "Standalone Ships"

    # Ships on sale with no standalone SKU, sold only in packs, so nothing
    # puts them into a cart on their own.
    attr_reader :changed_fields, :without_standalone

    def initialize(options = {})
      super

      @changed_fields = {}
      @without_standalone = []
    end

    def run(model)
      return if model.blank? || model.rsi_id.blank? || model.rsi_chassis_id.blank?

      data = load_pledge_store_data(model)

      pledge_data = data&.find { |item| item["id"] == model.rsi_id.to_s }

      return if pledge_data.blank?

      pledge_price = if pledge_data.dig("msrp").present?
        pledge_data.dig("msrp") / 100.0
      elsif model.pledge_price.present?
        model.pledge_price
      end

      # The upgrades the store sells into the ship today; one seen once stays
      # seen, as most come back for a sale.
      ccu_on_sale = Array(pledge_data["upgrades"]).any?

      # The cart needs a SKU, not the ship. An upgrade SKU keeps its id across
      # sales, so one RSI leaves out today is kept; whether it is on sale is
      # `ccu_on_sale`. A ship no longer sold on its own loses its standalone
      # SKU, unless RSI could not be asked.
      standalone_sku_id = standalone_sku_id(pledge_data["skus"])
      upgrade_sku_id = Array(pledge_data["upgrades"]).first&.dig("id")

      model.update!(
        rsi_pledge_slug: pledge_data["slug"],
        rsi_ctm_url: pledge_data.dig("media", "ctm"),
        rsi_pledge_value: pledge_data.dig("msrp"),
        on_sale: pledge_data["purchasable"],
        pledge_price: nil_or_decimal(pledge_price),
        ccu_on_sale:,
        ccu_target_seen_at: model.ccu_target_seen_at || (Time.current if ccu_on_sale),
        rsi_standalone_sku_id: (standalone_sku_id == :unknown) ? model.rsi_standalone_sku_id : standalone_sku_id&.to_i,
        rsi_upgrade_sku_id: upgrade_sku_id&.to_i || model.rsi_upgrade_sku_id
      )

      without_standalone << model if model.on_sale && model.rsi_standalone_sku_id.nil?

      fields = model.saved_changes.keys - UNREPORTED_COLUMNS
      changed_fields[model.id] = fields.sort if fields.any?
    end

    # The ship's `skus` mix its upgrade, its standalone versions, packages and
    # packs, all with the subtitle "Pledge". Only a search by slug says which
    # store category each is in. A warbond SKU cannot be paid with store
    # credit, so a regular one wins. `:unknown` when RSI gave no usable answer.
    private def standalone_sku_id(skus)
      slugs = Array(skus).filter_map { |sku| sku["slug"] }
      return if slugs.empty?

      operation = [{operationName: "GetSkus", variables: {query: {skus: {slugs:}}}, query: get_skus_query}]
      response = fetch_graphql(operation.to_json)
      return :unknown unless response.success?

      body = JSON.parse(response.body)
      resources = body.first&.dig("data", "store", "search", "resources") if body.is_a?(Array) && body.first.is_a?(Hash)
      return :unknown unless resources.is_a?(Array)

      standalone = resources.select { |sku| sku.is_a?(Hash) && sku["subtitle"] == STANDALONE_CATEGORY }

      (standalone.find { |sku| !sku["isWarbond"] } || standalone.first)&.dig("id")
    rescue JSON::ParserError => e
      Appsignal.report_error(e)
      :unknown
    end

    private def get_skus_query
      <<~GRAPHQL
        query GetSkus($query: SearchQuery) {
          store(name: "pledge") {
            search(query: $query) {
              resources {
                id
                subtitle
                ... on TySku {
                  isWarbond
                }
              }
            }
          }
        }
      GRAPHQL
    end

    private def load_pledge_store_data(model)
      operation = [{operationName: "GetShip", variables: get_ship_variables(model), query: get_ship_query}]

      response = fetch_graphql(operation.to_json)

      return unless response.success?

      begin
        pledge_store_data = JSON.parse(response.body)
        pledge_store_data.first.dig("data", "store", "search", "resources")
      rescue JSON::ParserError => e
        Appsignal.report_error(e)
        Rails.logger.error "Pledge Store Data could not be parsed: #{response.body}"
        []
      end
    end

    private def get_ship_variables(model)
      {
        query: {
          ships: {
            chassisId: [model.rsi_chassis_id.to_s],
            imageComposer: [
              {
                name: "1024",
                size: "SIZE_900",
                ratio: "RATIO_16_9",
                extension: "WEBP"
              },
              {
                name: "1440",
                size: "SIZE_1000",
                ratio: "RATIO_16_9",
                extension: "WEBP"
              },
              {
                name: "2048",
                size: "SIZE_1100",
                ratio: "RATIO_16_9",
                extension: "WEBP"
              }
            ],
            unslottedMedia: true
          }
        }
      }
    end

    private def get_ship_query
      <<~GRAPHQL
        query GetShip($query: SearchQuery) {
            store(name: "pledge", browse: true) {
                search(query: $query) {
                    count
                    resources {
                        ...RSIShipFragment
                        __typename
                    }
                    __typename
                }
            __typename
            }
        }

        fragment RSIShipFragment on RSIShip {
            ...RSIShipBaseFragment
            isCustomizable
            body
            excerpt
            size
            maxCrew
            minCrew
            mass
            length
            beam
            height
            maxScmSpeed
            cargoCapacity
            afterburnerSpeed
            rotation_x
            rotation_y
            rotation_z
            offset_x
            offset_y
            offset_z
            viewable
            hasBuyingOptions
            chassisId
            skus {
            ...TySkuShipSkuFragment
            __typename
            }
            paints {
            ...TySkuShipSkuFragment
            __typename
            }
            shipVariants {
            ...RSIShipVariantFragment
            __typename
            }
            upgrades {
            ...TySkuUpgradeFragment
            __typename
            }
            manufacturer {
            ...RSIManufacturerMinimalFragment
            __typename
            }
            weapons {
            ...RSIShipWeaponFragment
            __typename
            }
            modular {
            ...RSIShipModularFragment
            __typename
            }
            propulsions {
            ...RSIShipPropulsionFragment
            __typename
            }
            avionics {
            ...RSIShipAvionicFragment
            __typename
            }
            thrusters {
            ...RSIShipThrusterFragment
            __typename
            }
            imageComposer {
            ...ImageComposerFragment
            __typename
            }
            media {
            ...TyItemMediaCtmFragment
            __typename
            }
            __typename
        }

        fragment TySkuUpgradeFragment on TySku {
          id
          title
          subtitle
          slug
          isWarbond
          stock {
            ...TyStockFragment
            __typename
          }
          __typename
        }

        fragment TyStockFragment on TyStock {
          unlimited
          show
          available
          backOrder
          qty
          backOrderQty
          level
          __typename
        }

        fragment RSIShipVariantFragment on RSIShip {
          id
          title
          slug
          msrp
          chassisId
          media {
              thumbnail {
                storeSmall
              __typename
            }
            __typename
          }
          __typename
        }

        fragment RSIShipWeaponFragment on RSIShipWeapon {
          description
          manufacturerId
          manufacturerName
          model
          name
          quantity
          size
          __typename
          weaponId
        }

        fragment RSIShipAvionicFragment on RSIShipAvionic {
          description
          manufacturerId
          manufacturerName
          model
          name
          quantity
          size
          __typename
          avionicId
        }

        fragment RSIShipModularFragment on RSIShipModular {
          description
          manufacturerId
          manufacturerName
          model
          name
          quantity
          size
          __typename
          modularId
        }

        fragment RSIShipPropulsionFragment on RSIShipPropulsion {
          description
          manufacturerId
          manufacturerName
          model
          name
          quantity
          size
          __typename
          propulsionId
        }

        fragment RSIShipThrusterFragment on RSIShipThruster {
          description
          manufacturerId
          manufacturerName
          model
          name
          quantity
          size
          __typename
          thrusterId
        }

        fragment RSIManufacturerMinimalFragment on RSIManufacturer {
          name
          __typename
        }

        fragment ImageComposerFragment on ImageComposer {
          name
          slot
          url
          __typename
        }

        fragment TyItemMediaCtmFragment on TyItemMedia {
          ctm
          __typename
        }

        fragment RSIShipBaseFragment on RSIShip {
          id
          title
          name
          url
          slug
          type
          focus
          msrp
          purchasable
          productionStatus
          lastUpdate
          publishStart
          __typename
        }

        fragment TySkuShipSkuFragment on TySku {
          id
          title
          slug
          productId
          imageComposer {
              slot
            url
            name
            __typename
          }
          __typename
        }
      GRAPHQL
    end

    private def extract_price(element)
      raw_price = element.text

      price_match = raw_price.match(/^\$(\d?,?\d+.\d+)$/)

      return if price_match.blank?

      price_match[1].gsub(/[$,]/, "").to_d
    end
  end
end
