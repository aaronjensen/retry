class Retry
  include ::Telemetry::Dependency
  extend Retry::Telemetry::Register

  initializer :errors

  def millisecond_intervals
    @millisecond_intervals ||= [0].to_enum
  end
  attr_writer :millisecond_intervals

  def action_executed(&action)
    unless action.nil?
      self.action_executed = action
    end

    @action_executed
  end
  attr_writer :action_executed

  def self.build(*errors, millisecond_intervals: nil)
    errors = errors.flatten
    instance = new(errors)
    instance.millisecond_intervals = millisecond_intervals&.to_enum
    instance
  end

  def self.configure(receiver, *errors, millisecond_intervals: nil, attr_name: nil)
    attr_name ||= :rtry
    instance = build(errors, millisecond_intervals: millisecond_intervals)
    receiver.public_send("#{attr_name}=", instance)
    instance
  end

  def self.call(*errors, millisecond_intervals: nil, &action)
    instance = build(*errors, millisecond_intervals: millisecond_intervals)
    instance.(&action)
  end

  def call(&action)
    retries = 0

    error = nil
    probe = proc { |e| error = e }

    loop do
      success = Try.(*errors, error_probe: probe) do
        action.call(retries)
      end

      action_executed&.call(retries)

      break if success

      retries += 1

      interval = millisecond_intervals.next

      telemetry.record :retried, Retry::Telemetry::Data.new(retries, error.class, interval)

      break if interval.nil?

      sleep (interval/1000.0)
    end

    unless error.nil?
      raise error
    end

    retries
  end
end
