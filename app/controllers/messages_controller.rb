class MessagesController < ApplicationController
  before_action :set_message, only: [:show]

  def index
    # Load conversations grouped by customer, sorted by most recent activity
    @conversations = current_user.business.messages
                       .includes(:customer)
                       .group_by(&:customer)
                       .sort_by { |customer, messages| messages.map(&:created_at).max }
                       .reverse
                       .to_h
  end

  def show
  end

  def create
    @customer = current_user.business.customers.find(params[:customer_id])

    # Queue the message to be sent via Twilio
    SendMessageJob.perform_later(@customer.id, message_params[:body], current_user.business.id)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.append("messages", "") }
      format.html { redirect_to messages_path, notice: 'Message sent successfully.' }
    end
  end

  private

  def set_message
    @message = current_user.business.messages.find(params[:id])
  end

  def message_params
    params.require(:message).permit(:body)
  end
end
