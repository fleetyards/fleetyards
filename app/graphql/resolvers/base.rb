# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  class Base
    attr_accessor :obj, :args, :ctx

    def call(obj, args, ctx)
      self.obj = obj
      self.args = args
      self.ctx = ctx

      resolve
    end

    def resolve
      raise NotImplementedError
    end

    private def current_user
      ctx[:current_user]
    end

    private def current_ability
      ::Ability.new(current_user)
    end
  end
end
