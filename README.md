# retry

Retry an execution that terminates with an error

## Overview

The `Retry` library provides basic retry functionality with a clear and simple API. It supports:

- Retrying on any error
- Retrying on a specific error
- Retrying based on a list of possible errors
- Retrying once or many times
- Backoff intervals that allow delaying between retries

## Examples

### Retry on Any Error

Any error will cause the block to retry. The block will only retry once.

``` ruby
tries = 0
raise_error = true

Retry.() do
  tries += 1

  # The raise_error variable is true during the first iteration
  # RuntimeError will be raised during the first iteration
  # The block will be executed once again without raising an error
  if raise_error
    raise_error = false
    raise RuntimeError
  end
end

puts tries
# => 2
```

### Retry on a Specific Error

The block will be retried only if the specified error is raised in the block.

``` ruby
tries = 0
raise_error = true

SomeError = Class.new(RuntimeError)

Retry.(SomeError) do
  tries += 1
  puts tries

  # The raise_error variable is true during the first iteration
  # SomeError will be raised during the first iteration
  # and the block will be executed once again
  if raise_error
    raise_error = false
    raise SomeError
  end

  # Will raise RuntimeError in the second iteration
  # RuntimeError is not retried, and so the program terminates
  raise RuntimeError
end

# => 1
# => 2
# => RuntimeError
```

### Retry on Multiple Specific Errors

The block will be retried if any of the the specified errors are raised in the block.

``` ruby
tries = 0
raise_error = true

SomeError = Class.new(RuntimeError)
SomeOtherError = Class.new(RuntimeError)

Retry.(SomeError, SomeOtherError) do
  tries += 1
  puts tries

  # The raise_error variable is true during the first iteration
  # SomeOtherError will be raised during the first iteration
  # and the block will be executed once again
  if raise_error
    raise_error = false
    raise SomeOtherError
  end

  # Will raise RuntimeError in the second iteration
  # RuntimeError is not retried, and so the program terminates
  raise RuntimeError
end

# => 1
# => 2
# => RuntimeError
```

### Retry and Back Off

The block will be retried up to the number of delay intervals specified.

The `millisecond_intervals` parameter can be used without specifying a specific error, when specifying a specific error, or when specifying a list of possible errors.

``` ruby
tries = 0

SomeError = Class.new(RuntimeError)
SomeOtherError = Class.new(RuntimeError)

Retry.(SomeError, SomeOtherError, millisecond_intervals: [100, 200]) do
  tries += 1
  puts tries

  raise SomeError
end

# => 1 (first attempt)
# => 2 (second attempt, after 100 ms delay)
# => 3 (third attempt, after 200 ms delay)
# => SomeError
```

## License

The `retry` library is released under the [MIT License](https://github.com/eventide-project/retry/blob/master/MIT-License.txt).
