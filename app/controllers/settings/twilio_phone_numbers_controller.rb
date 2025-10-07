class Settings::TwilioPhoneNumbersController < ApplicationController
  before_action :authenticate_user!

  def index
    @twilio_phone_numbers = current_user.business.twilio_phone_numbers.order(created_at: :desc)
  end

  def new
    @twilio_phone_number = current_user.business.twilio_phone_numbers.build
  end

  def create
    @twilio_phone_number = current_user.business.twilio_phone_numbers.build(twilio_phone_number_params)
    @twilio_phone_number.status = :pending

    if @twilio_phone_number.save
      redirect_to settings_twilio_phone_numbers_path, notice: 'Phone number request submitted successfully. Pending admin approval.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def twilio_phone_number_params
    params.require(:twilio_phone_number).permit(:phone_number, :location)
  end
end
