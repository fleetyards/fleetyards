# frozen_string_literal: true

json.partial! "api/v1/public/users/user", user: @user

# Outside the cached fragment: it depends on who is reading. Absent rather than
# false when the reader gets no answer, as on every roster.
online = online_status_for(@user) if @show_presence
json.online online unless online.nil?
