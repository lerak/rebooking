module MessagesHelper
  def format_message_timestamp(datetime)
    return '' if datetime.nil?

    now = Time.current
    time_str = datetime.strftime('%I:%M %p')

    if datetime.to_date == now.to_date
      "Today at #{time_str}"
    elsif datetime.to_date == now.to_date - 1.day
      "Yesterday at #{time_str}"
    elsif datetime.year == now.year
      datetime.strftime('%b %d at %I:%M %p')
    else
      datetime.strftime('%b %d, %Y at %I:%M %p')
    end
  end
end
