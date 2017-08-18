# encoding: utf-8
# frozen_string_literal: true

json.id user.id
json.email user.email
json.username user.username
json.avatar user.avatar(48)
json.isAdmin user.admin?
json.created_at user.created_at
json.updated_at user.updated_at
