# frozen_string_literal: true

require "asyncapi_helper"

class RafflesChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "raffles", channel_class: RafflesChannel do
    broadcast "A raffle or one of its entries changed" do
      operationId "receiveRaffleChange"
      message ::Cable::V1::Schemas::RaffleChangedMessage
    end
  end

  test "broadcasts the raffle id when the raffle changes" do
    raffle = create(:raffle)

    payloads = assert_asyncapi_broadcast do
      raffle.update!(title: "Renamed")
    end

    assert_equal raffle.id, payloads.first["raffleId"]
  end

  test "broadcasts the raffle id when somebody enters" do
    raffle = create(:raffle)

    payloads = assert_asyncapi_broadcast do
      create(:raffle_entry, raffle:)
    end

    assert_equal raffle.id, payloads.first["raffleId"]
  end
end
