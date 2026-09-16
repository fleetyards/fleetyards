# frozen_string_literal: true

class AddPartsToAnnouncements < ActiveRecord::Migration[8.1]
  def change
    # An announcement is not always one message. The Fleet Ops beta copy is two
    # Discord messages and a two-post social thread, and where the break falls
    # is an editorial decision -- Tours moved into the second Discord message
    # to make room for Inventories in the first. A composer that truncates
    # picks that boundary by character count and silently drops whatever came
    # after it.
    #
    # Ordered lists rather than one long body with a separator in it, because
    # the in-app body is markdown and every candidate separator (`---` first
    # among them) is already a markdown construct an author may legitimately
    # write.
    add_column :announcements, :discord_parts, :text, array: true, default: [], null: false
    add_column :announcements, :social_parts, :text, array: true, default: [], null: false

    # Replaced by social_parts, whose single-element case is exactly what this
    # held. Nothing has shipped on this column.
    remove_column :announcements, :social_body, :text
  end
end
