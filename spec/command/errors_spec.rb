require 'spec_helper'

describe Command::Errors do
  let(:errors) { Command::Errors.new }

  describe '#add' do
    it 'adds the error' do
      errors.add :attribute, :some_error, 'some error description'
      expect(errors[:attribute]).to eq([{ code: :some_error, message: 'some error description' }])
    end

    it 'adds the same error only once' do
      errors.add :attribute, :some_error, 'some error description'
      expect(errors[:attribute]).to eq([{ code: :some_error, message: 'some error description' }])
    end

    it 'tries to localize the error message if possible' do
      expect(I18n).to receive(:t!).with(:bad_post_code, anything).and_return("Very bad post code")

      errors.add :address, :invalid, :bad_post_code
      expect(errors[:address]).to eq([{ code: :invalid, message: "Very bad post code" }])
    end

    context 'when the errors are for a i18n-scoped class' do
      let(:scoped_klass) { double('Command', i18n_scope: 'my.custom.scope') }
      let(:errors) { Command::Errors.new(source: scoped_klass) }

      it "takes the scope into account for localization" do
        allow(I18n).to receive(:t!).with(:bad_post_code, anything).
          and_return("Bad error message")
        expect(I18n).to receive(:t!).with(:bad_post_code, hash_including(scope: 'my.custom.scope')).
          and_return("Correct error message")

        errors.add :address, :invalid, :bad_post_code
        expect(errors[:address]).to eq([{ code: :invalid, message: "Correct error message" }])
      end
    end
  end

  describe '#add_multiple_errors' do
    let(:errors_list) do
      {
        attribute_a: [{ code: :some_error, message: 'some error description' }],
        attribute_b: [{ code: :another_error, message: 'another error description' }],
      }
    end

    before do
      errors.add_multiple_errors errors_list
    end

    it 'populates itself with the added errors' do
      expect(errors[:attribute_a]).to eq(errors_list[:attribute_a])
      expect(errors[:attribute_b]).to eq(errors_list[:attribute_b])
    end
  end
end
