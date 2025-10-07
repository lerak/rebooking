class TwilioWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  skip_before_action :redirect_if_no_business
  before_action :verify_twilio_signature

  def inbound
    from = params['From']
    body = params['Body']
    message_sid = params['MessageSid']

    # Find or create customer by phone number
    customer = Customer.find_by(phone: from)

    unless customer
      render plain: 'OK', status: :ok
      return
    end

    # Create message record for inbound SMS
    message = Message.create!(
      customer: customer,
      business: customer.business,
      direction: 'inbound',
      status: 'received',
      body: body,
      twilio_sid: message_sid
    )

    # Check for STOP/HELP keywords and process
    parser = MessageParser.new(body)

    if parser.stop?
      ConsentManager.new(customer).opt_out(reason: 'SMS STOP reply', metadata: { source: 'sms_reply' })
      render plain: 'OK', status: :ok
      return
    end

    if parser.help?
      # Send auto-reply for HELP keyword
      help_message = "Reply STOP to unsubscribe. For support, contact #{customer.business.name}."
      SendMessageJob.perform_later(customer.id, help_message, customer.business.id)
    end

    # Broadcast Turbo Stream for real-time inbox update
    message.broadcast_append_to(
      "business_#{customer.business.id}_messages",
      target: "messages",
      partial: "messages/message",
      locals: { message: message }
    )

    render plain: 'OK', status: :ok
  end

  def status_callback
    message_sid = params['MessageSid']
    message_status = params['MessageStatus']
    error_code = params['ErrorCode']
    error_message = params['ErrorMessage']

    # Find message by Twilio SID
    message = Message.find_by(twilio_sid: message_sid)

    return render plain: 'OK', status: :ok unless message

    # Update message status based on callback
    case message_status
    when 'queued'
      message.update!(status: 'queued')
    when 'sent'
      message.update!(status: 'sent')
    when 'delivered'
      message.update!(status: 'delivered', delivered_at: Time.current)
    when 'failed', 'undelivered'
      message.update!(
        status: message_status,
        error_message: error_message || "Error code: #{error_code}"
      )
    end

    render plain: 'OK', status: :ok
  end

  private

  def verify_twilio_signature
    # Get Twilio auth token from credentials
    auth_token = Rails.application.credentials.dig(:twilio, :auth_token)

    # Get the signature from request headers
    signature = request.headers['X-Twilio-Signature']

    # Get the full URL (Twilio needs the full URL including query params)
    url = request.original_url

    # Get the POST params
    post_params = params.except(:controller, :action).to_unsafe_h

    # Validate signature using Twilio's validator
    validator = Twilio::Security::RequestValidator.new(auth_token)

    unless validator.validate(url, post_params, signature)
      render plain: 'Unauthorized', status: :unauthorized
    end
  end
end
