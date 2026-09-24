# frozen_string_literal: true

require "test_helper"

class ResetLocaleTest < ActiveSupport::TestCase
  teardown { I18n.locale = I18n.default_locale }

  def middleware(&app)
    Middleware::ResetLocale.new(app)
  end

  test "a locale the request set does not outlive it" do
    middleware do |_env|
      I18n.locale = :de
      [200, {}, []]
    end.call({})

    assert_equal I18n.default_locale, I18n.locale
  end

  test "a request starts from the default locale whatever the thread held" do
    seen = nil
    I18n.locale = :fr

    middleware do |_env|
      seen = I18n.locale
      [200, {}, []]
    end.call({})

    assert_equal I18n.default_locale, seen
  end

  test "the locale is reset when the request raises" do
    assert_raises(RuntimeError) do
      middleware do |_env|
        I18n.locale = :de
        raise "boom"
      end.call({})
    end

    assert_equal I18n.default_locale, I18n.locale
  end
end
