class TimeFormatter
  attr_reader :duration

  def initialize(duration_in_business_seconds)
    @duration = duration_in_business_seconds.to_i
  end

  def seconds
    duration % 60
  end

  def minutes
    (duration / 60) % 60
  end

  def hours
    (duration / (60 * 60)) % (workday_length_seconds / (60 * 60))
  end

  def working_days
    (duration / workday_length_seconds).to_i
  end

  def workday_length_seconds
    arbitrary_workday = Date.new(2017,3,31)
    Time.work_hours_total(arbitrary_workday)
  end

  def to_s
    %I{working_days hours minutes seconds}.map do |part|
      amount = self.send(part).to_i
      description = part.to_s
      description.gsub!(/s$/, '') if amount == 1
      description.gsub!(/_/, ' ')
      [amount, description] if amount > 0
    end.compact.take(3).map do |part|
      part.join(" ")
    end.join(" ")
  end
end
