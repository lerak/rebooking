class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :set_current_tenant
  before_action :redirect_if_no_business

  private

  def set_current_tenant
    ActsAsTenant.current_tenant = current_user&.business if current_user&.business.present?
  end

  def redirect_if_no_business
    if user_signed_in? && current_user.business.blank? && !devise_controller? && controller_name != "businesses"
      redirect_to edit_settings_business_path, alert: "Please complete your business profile to continue."
    end
  end
end
