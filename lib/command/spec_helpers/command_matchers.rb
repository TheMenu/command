# TODO: Rewrite this as a pure module definition to remove dependency on RSpec
require 'rspec/matchers'

# expect(command).to be_unsuccessful
# expect(command).to be_unsuccessful.with(hash_of_errors)
RSpec::Matchers.define :be_unsuccessful do |options|
  chain :with, :expected_errors

  match do |command|
    if expected_errors.nil?
      command.failure?
    else
      command.failure? && (command.errors == expected_errors)
    end
  end

  failure_message do |command|
    if command.failure?
      "expected that #{command} errors should be #{expected_errors} but errors are #{command.errors} "
    else
      "expected that #{command} should not be successful"
    end
  end
end

# expect(command).to be_successful
# expect(command).to be_successful.with("command_result")
RSpec::Matchers.define :be_successful do |options|
  chain :with, :expected_result

  success = nil

  match do |command|
    success = command.respond_to?(:successful?) ? command.successful? : command.success? # to be compatible with Rails 6 which add a helper with identical name
    if expected_result.nil?
      success
    else
      success && command.result == expected_result
    end
  end

  failure_message do |command|
    if success
      "expected that #{command} result should be #{expected_result} but is #{command.result}"
    else
      "expected that #{command} should be successful"
    end
  end
end
