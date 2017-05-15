# frozen_string_literal: true

class ComponentsController < ApplicationController
  before_action :set_active_nav

  skip_authorization_check
  before_action :authenticate_user!, only: []

  def propulsion
    authorize! :index, :components
    render :index
  end

  def ordnance
    authorize! :index, :components
    render :index
  end

  def modular
    authorize! :index, :components
    render :index
  end

  def avionics
    authorize! :index, :components
    render :index
  end

  def show
    authorize! :show, component
  end

  private def components
    @components ||= Component
                    .enabled
                    .includes(:category).where(component_categories: { slug: @components_type })
                    .order('components.name asc')
                    .page(params.fetch(:page, nil))
                    .per(20)
  end
  helper_method :components

  private def components_type
    @components_type ||= action_name
  end
  helper_method :components_type

  private def component
    @component ||= Component.enabled.where(id: params.fetch(:id, nil)).first
  end
  helper_method :component

  private def set_active_nav
    @active_nav = "#{components_type}_component"
  end
end
