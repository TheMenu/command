require 'spec_helper'

describe SimpleCommand::Errors do
  let(:errors) { SimpleCommand::Errors.new }

  describe '#add' do
    before do
      errors.add :attribute, :some_error, 'some error description'
    end

    it 'adds the error' do
      expect(errors[:attribute]).to eq([{ code: :some_error, message: 'some error description' }])
    end

    it 'adds the same error only once' do
      errors.add :attribute, :some_error, 'some error description'
      expect(errors[:attribute]).to eq([{ code: :some_error, message: 'some error description' }])
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
