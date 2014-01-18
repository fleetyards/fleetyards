class ManufacturersController < ApplicationController
  def edit
  end

  def update
    if manufacturer.update(manufacturer_params)
      redirect_to ships_path, notice: "Update success"
    else
      redirect_to ships_path, error: "Update failure"
    end
  end

  private def manufacturer
  end
  helper_method :manufacturer
end
