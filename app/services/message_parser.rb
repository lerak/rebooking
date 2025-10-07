# Service class to parse SMS messages for keywords
class MessageParser
  STOP_KEYWORDS = %w[stop stopall unsubscribe cancel end quit].freeze
  HELP_KEYWORDS = %w[help info].freeze

  def initialize(message_body)
    @message_body = message_body.to_s.strip.downcase
  end

  # Check if message contains a STOP keyword
  # @return [Boolean] true if message contains STOP keyword
  def stop?
    STOP_KEYWORDS.any? { |keyword| @message_body == keyword }
  end

  # Check if message contains a HELP keyword
  # @return [Boolean] true if message contains HELP keyword
  def help?
    HELP_KEYWORDS.any? { |keyword| @message_body == keyword }
  end

  # Check if message contains any special keyword
  # @return [Boolean] true if message contains STOP or HELP keyword
  def has_keyword?
    stop? || help?
  end

  # Get the type of keyword detected
  # @return [Symbol, nil] :stop, :help, or nil if no keyword
  def keyword_type
    return :stop if stop?
    return :help if help?
    nil
  end
end
