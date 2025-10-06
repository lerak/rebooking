class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  set_current_tenant_through_filter
  before_action :set_current_tenant

  private

  def set_current_tenant
    set_current_tenant(current_user.business) if current_user
  end
end
