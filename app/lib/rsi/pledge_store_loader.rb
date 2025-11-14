module Rsi
  class PledgeStoreLoader < ::Rsi::BaseLoader
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

      model.update!(
        rsi_pledge_slug: pledge_data["slug"],
        rsi_ctm_url: pledge_data.dig("media", "ctm"),
        rsi_pledge_value: pledge_data.dig("msrp"),
        on_sale: pledge_data["purchasable"],
        pledge_price: nil_or_decimal(pledge_price)
      )
    end

    private def load_pledge_store_data(model)
      operation = [{operationName: "GetShip", variables: get_ship_variables(model), query: get_ship_query}]

      response = fetch_graphql(operation.to_json)

      return unless response.success?

      begin
        pledge_store_data = JSON.parse(response.body)
        pledge_store_data.first.dig("data", "store", "search", "resources")
      rescue JSON::ParserError => e
        Sentry.capture_exception(e)
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
