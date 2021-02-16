require 'spec_helper'

describe Command::ErrorHandling do
  before do
    instance

    allow(I18n).to receive(:t).and_call_original
  end

  let(:klass) do
    prepend_in = Class.new
    prepend_in.prepend(Command::SimpleCommand) # To provide contract ErrorHandling relies on
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

  describe '.add_error' do
    context 'when error messages can be passed as i18n key or as String' do
      it 'String' do
        instance.add_error(:name, :invalid, "Name must be present")
        expect(instance.errors).to have_key(:name)
        expect(instance.errors[:name]).to include(code: :invalid, message: "Name must be present")
      end

      it 'i18n' do
        expect(I18n).to receive(:t).with(:bad_post_code, anything).and_return("Very bad post code")

        instance.add_error(:address, :invalid, :bad_post_code)
        expect(instance.errors).to have_key(:address)
        expect(instance.errors[:address]).to include(code: :invalid, message: "Very bad post code")
      end
    end

    it 'can be configured to use another i18n_scope' do
      allow(I18n).to receive(:t).with(:bad_post_code, anything)
                                .and_return("Bad error message")
      expect(I18n).to receive(:t).with(:bad_post_code, hash_including(scope: 'my.custom.scope'))
                                 .and_return("Correct error message")


      klass.i18n_scope = 'my.custom.scope'
      instance.add_error(:address, :invalid, :bad_post_code)
      expect(instance.errors).to have_key(:address)
      expect(instance.errors[:address]).to include(code: :invalid, message: "Correct error message")
    end
  end

  it 'can import errors from any object responding to errors.details and errors.messages' do
    recordlike_object.errors.messages[:name] = ["Bad name!"]
    recordlike_object.errors.details[:name] = [{error: :bad_name}]

    instance.merge_errors_from_record(recordlike_object)

    expect(instance.errors).to have_key(:name)
    expect(instance.errors[:name]).to include(code: :bad_name, message: "Bad name!")
  end

  it 'can give a structure containing both error messages and codes' do
    allow(I18n).to receive(:t).with(:bad_post_code, anything)
                              .and_return("Bad post code!")
    instance.add_error(:address, :invalid, :bad_post_code)

    expect(instance.full_errors).to have_key(:address)
    expect(instance.full_errors[:address]).to include(hash_including(code: :invalid, message: "Bad post code!"))
  end
end
