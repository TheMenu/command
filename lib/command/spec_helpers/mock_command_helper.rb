# frozen_string_literal: true

module Command
  module SpecHelpers
    module MockCommandHelper
      NO_PARAMS_PASSED = Object.new

      def mock_successful_command(command, result:, params: NO_PARAMS_PASSED)
        mock_command(command, success: true, result: result, params: params)
      end

=begin
    Example :
      mock_unsuccessful_command(ExtinguishDebtAndLetterIt, errors: {
        entry: { not_found: "Couldn't find Entry with 'document_identifier'='foo'" }
      })

    is equivalent to
      mock_command(ExtinguishDebtAndLetterIt,
        success: false,
        result: nil,
        errors: {:entry=>[code: :not_found, message: "Couldn't find Entry with 'document_identifier'='foo'"]},
      )
=end
      def mock_unsuccessful_command(command, errors:, params: NO_PARAMS_PASSED)
        mock_command(command, success: false, errors: errors, params: params)
      end

      def mock_command(command, success:, result: nil, errors: {}, params: NO_PARAMS_PASSED)
        if Object.const_defined?('FakeCommandErrors')
          klass = Object.const_get('FakeCommandErrors')
        else
          klass = Object.const_set 'FakeCommandErrors', Class.new
          klass.prepend Command
        end
        fake_command = klass.new
        if errors.any?
          errors.each do |attr, details|
            details.each do |code, message|
              fake_command.add_error(attr, code, message)
            end
          end
        end
        double = instance_double(command)
        allow(double).to receive(:as_sub_command).and_return(double)
        allow(double).to receive(:call).and_return(double)
        allow(double).to receive(:success?).and_return(success)
        allow(double).to receive(:failure?).and_return(!success)
        allow(double).to receive(:result).and_return(result)
        allow(double).to receive(:errors).and_return(fake_command.errors)
        allow(double).to receive(:full_errors).and_return(fake_command.full_errors)
        allow(double).to receive(:has_error?) { |attribute, code| fake_command.has_error? attribute, code }
        if params == NO_PARAMS_PASSED
          allow(command).to receive(:call).and_return(double)
          allow(command).to receive(:new).and_return(double)
        else
          mock_params = Array.wrap(params)
          hash_params = mock_params.extract_options!
          allow(command).to receive(:call).with(*mock_params, **hash_params).and_return(double)
          allow(command).to receive(:new).with(*mock_params, **hash_params).and_return(double)
        end
        double
      end
    end
  end
end
