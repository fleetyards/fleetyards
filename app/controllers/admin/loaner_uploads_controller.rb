# frozen_string_literal: true

module Admin
  class LoanerUploadsController < ::Admin::ApplicationController
    before_action :set_active_nav

    def new
      authorize! :upload_loaners, :admin_models
    end

    def create
      authorize! :upload_loaners, :admin_models

      html_content = nil

      file_data = upload_params[:html_upload]
      if file_data.respond_to?(:read)
        html_content = file_data.read
      elsif file_data.respond_to?(:path)
        html_content = File.read(file_data.path)
      else
        render 'new', error: I18n.t(:'messages.loaner_upload.failure', class_name: file_data.class.name, content: file_data.inspect)
        Rails.logger.error "Bad file_data: #{file_data.class.name}: #{file_data.inspect}"
      end

      Rsi::LoanerLoader.new.run(html_content) if html_content.present?

      redirect_to admin_models_path(params: index_back_params), notice: I18n.t(:'messages.loaner_upload.success')
    end

    private def set_active_nav
      @active_nav = 'admin-models'
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:models_filters],
        page: session[:models_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def upload_params
      @upload_params ||= params.require(:loaner_upload).permit(
        :html_upload
      )
    end
  end
end
