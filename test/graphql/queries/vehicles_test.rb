# frozen_string_literal: true

require "test_helper"

describe 'vehicles query' do
  let(:context) { {} }
  let(:variables) { {} }
  # Call `result` to execute the query
  let(:result) do
    res = FleetyardsSchema.execute(
      query_string,
      context: context,
      variables: variables
    )
    # Print any errors
    puts res if res["errors"]

    res
  end
  # rubocop:disable Style/PercentLiteralDelimiters
  let(:query_string) { %|{ vehicles { name } }| }

  it "returns all vehicles" do
    assert_equal(result['data']['vehicles'], [{ 'name' => '600i' }, { 'name' => 'Andromeda' }])
  end
end
