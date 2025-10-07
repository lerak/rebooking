class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :set_current_tenant
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def set_current_tenant
    ActsAsTenant.current_tenant = current_user&.business
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:business_id])
    devise_parameter_sanitizer.permit(:account_update, keys: [:business_id])
  end
end
