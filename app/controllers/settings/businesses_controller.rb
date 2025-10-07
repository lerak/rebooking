class Settings::BusinessesController < ApplicationController
  skip_before_action :redirect_if_no_business
  before_action :set_or_build_business

  def edit
  end

  def update
    if @business.new_record?
      @business.assign_attributes(business_params)
      if @business.save
        current_user.update(business: @business)
        redirect_to root_path, notice: 'Business profile created successfully.'
      else
        render :edit, status: :unprocessable_entity
      end
    else
      if @business.update(business_params)
        redirect_to edit_settings_business_path, notice: 'Business settings updated successfully.'
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  private

  def set_or_build_business
    @business = current_user.business || Business.new
  end

  def business_params
    params.require(:business).permit(:name, :timezone, :reminder_hours_before)
  end
end
