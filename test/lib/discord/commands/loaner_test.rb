# frozen_string_literal: true

require "test_helper"
require "discord/commands/loaner"

module Discord
  module Commands
    class LoanerTest < ActiveSupport::TestCase
      setup do
        @model = create(:model, name: "Carrack")
        @loaner = create(:model, name: "Constellation Andromeda")
      end

      def call(name)
        ::Discord::Commands::Loaner.new(options: {"name" => name}).call
      end

      def add_loaner(model, loaner)
        model.model_loaners.create!(loaner_model: loaner)
      end

      test "lists the loaners a ship comes with" do
        add_loaner(@model, @loaner)

        content = call("Carrack")[:content]

        assert_includes content, "Constellation Andromeda"
        assert_includes content, "/ships/#{@loaner.slug}"
      end

      test "says so when a ship has no loaners" do
        assert_equal I18n.t("discord.commands.loaner.none", ship: "Carrack"), call("Carrack")[:content]
      end

      test "a hidden loaner is not listed" do
        @loaner.update!(hidden: true)
        add_loaner(@model, @loaner)

        assert_equal I18n.t("discord.commands.loaner.none", ship: "Carrack"), call("Carrack")[:content]
      end

      test "an unknown ship is reported rather than answered empty" do
        assert_includes call("Nonexistent")[:content], "Nonexistent"
      end

      test "a blank name asks for one" do
        assert_equal I18n.t("discord.commands.loaner.missing_query"), call(" ")[:content]
      end

      test "an ambiguous name lists candidates" do
        create(:model, name: "Hornet F7C")
        create(:model, name: "Hornet F7A")

        assert_includes call("Hornet")[:content], "Hornet F7C"
      end

      test "carries no flags, since a follow-up cannot set them" do
        add_loaner(@model, @loaner)

        assert_nil call("Carrack")[:flags]
      end
    end
  end
end
