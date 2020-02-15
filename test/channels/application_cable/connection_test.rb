# frozen_string_literal: true

require 'test_helper'

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    test 'connects with params' do
      # Simulate a connection opening by calling the `connect` method
      connect params: { token: 42 }

      # You can access the Connection object via `connection` in tests
      assert_equal connection.token, '42'
    end
  end
end
