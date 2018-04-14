require_relative '../automated_init'

context "Telemetry" do
  context "Retried" do
    rtry = Retry.new

    millisecond_intervals = [11, 111]
    errors = [Retry::Controls::ErrorA, Retry::Controls::ErrorB]

    sink = Retry.register_telemetry_sink(rtry)

    rtry.(errors, millisecond_intervals: millisecond_intervals) do |i|
      raise errors[i] if i == 0 # First attempt
      raise errors[i] if i == 1 # Second attempt (first retry)
    end

    test "3 cycles" do
      assert(sink.records.length == 3)
    end

    context "Cycles" do
      context "Failed" do
        millisecond_intervals.each_with_index do |millisecond_interval, i|
          telemetry_data = sink.records[i].data

          test "cycle [#{telemetry_data.cycle}]" do
            assert(telemetry_data.cycle == i)
          end

          test "error [#{telemetry_data.error}]" do
            assert(telemetry_data.error == errors[i])
          end

          test "millisecond_interval [#{telemetry_data.millisecond_interval}]" do
            assert(telemetry_data.millisecond_interval == millisecond_intervals[i])
          end
        end
      end

      context "Succeeded" do
        telemetry_data = sink.records.last.data

        test "cycle [#{telemetry_data.cycle}]" do
          assert(telemetry_data.cycle == 2)
        end
      end
    end
  end
end
