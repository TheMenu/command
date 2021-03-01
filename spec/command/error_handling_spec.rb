require 'spec_helper'

describe Command::ErrorHandling do
  before do
    instance

    allow(I18n).to receive(:t).and_call_original
  end

  let(:klass) do
    prepend_in = Class.new
    prepend_in.prepend(Command) # To provide contract ErrorHandling relies on
    prepend_in.prepend(described_class)
  end

  let(:instance) do
    klass.new
  end

  let(:recordlike_object) do
    OpenStruct.new(
      errors: OpenStruct.new(
        messages: {
        },
        details: {
        },
      ),
    )
  end

  it 'can import errors from any object responding to errors.details and errors.messages' do
    recordlike_object.errors.messages[:name] = ["Bad name!"]
    recordlike_object.errors.details[:name] = [{error: :bad_name}]

    instance.merge_errors_from_record(recordlike_object)

    expect(instance.errors).to have_key(:name)
    expect(instance.errors[:name]).to include(code: :bad_name, message: "Bad name!")
  end

  it 'can give a structure containing both error messages and codes' do
    allow(I18n).to receive(:t!).with(:bad_post_code, anything)
                              .and_return("Bad post code!")
    instance.add_error(:address, :invalid, :bad_post_code)

    expect(instance.full_errors).to have_key(:address)
    expect(instance.full_errors[:address]).to include(hash_including(code: :invalid, message: "Bad post code!"))
  end
end
