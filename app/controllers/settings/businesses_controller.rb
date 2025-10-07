class Settings::BusinessesController < ApplicationController
  before_action :set_business

  def edit
  end

  def update
    if @business.update(business_params)
      redirect_to edit_settings_business_path, notice: 'Business settings updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_business
    @business = current_user.business
  end

  def business_params
    params.require(:business).permit(:name, :timezone)
  end
end
