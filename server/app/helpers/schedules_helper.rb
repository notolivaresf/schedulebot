module SchedulesHelper
  def format_slot_date(date_string)
    date = Date.parse(date_string)
    date.strftime("%b/%-d/%Y")
  end

  def format_slot_time_range(start_time, end_time)
    start_hour, start_min = start_time.split(":").map(&:to_i)
    end_hour, end_min = end_time.split(":").map(&:to_i)

    start_formatted = format_time_12hr(start_hour, start_min)
    end_formatted = format_time_12hr(end_hour, end_min)

    "#{start_formatted} - #{end_formatted}"
  end

  private

  def format_time_12hr(hour, min)
    period = hour >= 12 ? "PM" : "AM"
    display_hour = hour % 12
    display_hour = 12 if display_hour == 0
    "#{display_hour}:#{'%02d' % min} #{period}"
  end
end
