# frozen_string_literal: true

# rubocop:disable Rails/ApplicationController
class ErrorsController < ActionController::Base
  def not_found
    respond_to do |format|
      format.html do
        render :error, status: :not_found, layout: 'error'
      end
      format.json do
        render json: { code: 'not_found', message: I18n.t('errors.not_found.message') }, status: :not_found
      end
      format.all do
        redirect_to '/404'
      end
    end
  end

  def method_not_allowed
    respond_to do |format|
      format.html do
        render :error, status: :method_not_allowed, layout: 'error'
      end
      format.json do
        render json: { code: 'method_not_allowed', message: I18n.t('errors.method_not_allowed.message') }, status: :method_not_allowed
      end
    end
  end

  def unprocessable_entity
    respond_to do |format|
      format.html do
        render :error, status: :unprocessable_entity, layout: 'error'
      end
      format.json do
        render json: { code: 'unprocessable_entity', message: I18n.t('errors.unprocessable_entity.message') }, status: :unprocessable_entity
      end
    end
  end

  def not_acceptable
    respond_to do |format|
      format.html do
        render :error, status: :not_acceptable, layout: 'error'
      end
      format.json do
        render json: { code: 'not_acceptable', message: I18n.t('errors.not_acceptable.message') }, status: :not_acceptable
      end
    end
  end

  def server_error
    respond_to do |format|
      format.html do
        render :error, status: :internal_server_error, layout: 'error'
      end
      format.json do
        render json: { code: 'server_error', message: I18n.t('errors.server_error.message') }, status: :internal_server_error
      end
    end
  end
end
# rubocop:enable Rails/ApplicationController
