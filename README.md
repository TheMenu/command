# Command

A simple, standardized way to build and use _Service Objects_ in Ruby.  

## Requirements

* At least Ruby 2.0+

It is used with Ruby 2.7 and Ruby 3 projects.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'command', github: 'TheMenu/command'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install command

## Usage

Here's a basic example of a command that check if a collection is empty or not 

```ruby
# define a command class
class CollectionChecker
  # put Command before the class' ancestors chain
  prepend Command

  # mandatory: define a #call method. its return value will be available
  #            through #result
  def call
    @collection.empty? || errors.add(:collection, :failure, "Your collection is empty !.")
    @collection.length
  end

  private

  # optional, initialize the command with some arguments
  # optional, initialize can be public or private, private is better ;-)
  def initialize(collection)
    @collection = collection
  end
end
```

in your locale file
```yaml
# config/locales/en.yml
en:
  activemodel:
    errors:
      models:
        authenticate_user:
          failure: Wrong email or password
```

Then, in your controller:

```ruby
class CollectionController < ApplicationController
  def create
    # initialize and execute the command
    command = CollectionChecker.call(params)

    # check command outcome
    if command.success?
      # command#result will contain the number of items, if any
      render json: { count: command.result }
    else
      render_error(
        message: "Payload is empty.",
        details: command.full_errors,
      )
    end
  end
  
  private
  
  def render_error(details:, message: "Bad request", code: "BAD_REQUEST", status: 400)
    payload = {
      error: {
        code: code,
        message: message,
        details: details,
      }
    }
    render status: status, json: payload
  end
end
```

When errors, the controller will return the following json :

```json
{
  "error": {
    "code": "BAD_REQUEST",
    "message": "Payload is empty",
    "details": {
      "collection": [
        {
          "code": "failure",
          "message": "Your collection is empty !."
        }
      ]
    }
  }
}
```

###  Subcommand

It is also possible to call sub command and stop run if failed :
```ruby
class CollectionChecker
  prepend Command

  def call
    assert_sub FormatChecker, @collection
    @collection.empty? || errors.add(:collection, :failure, "Your collection is empty !.")
    @collection.length
  end
end

class FormatChecker
  prepend Command
  
  def call
    @collection.is_a?(Array) || errors.add(:collection, :failure, "Not an array")
    @collection.class.name
  end

  def initialize(collection)
    @collection = collection
  end
end

command = CollectionChecker.call('foo')
command.success? # => false
command.failure? # => true
command.errors # => { collection: [ { code: :failure, message: "Not an array" } ] }
command.result # => nil 
```

You can get result from your sub command :
```ruby
class CrossProduct
  prepend Command

  def call
    product = assert_sub Multiply, @first, 100
    product / @second
  end

  def initialize(first, second)
    @first = first
    @second = second 
  end
end

class Multiply
  def call 
    @first * @second
  end
  # ...
end
```

### Merge errors from ActiveRecord instance
```ruby
class UserCreator
  prepend Command
  
  def call
    @user.save!
  rescue ActiveRecord::RecordInvalid
    merge_errors_from_record(@user) 
  end
end

invalid_user = User.new
command = UserCreator.call(invalid_user)
command.success? # => false
command.failure? # => true
command.errors # => { name: [ { code: :required, message: "must exist" } ] }
```

### Error message

The third parameter is the message.
```ruby
errors.add(:item, :invalid, 'It is invalid !')
```

A symbol can be used and the sentence will be generated with I18n (if it is loaded) : 
```ruby
errors.add(:item, :invalid, :invalid_item)
```

Scope can be used with symbol : 
```ruby
errors.add(:item, :invalid, :'errors.invalid_item')
# equivalent to
errors.add(:item, :invalid, :invalid_item, scope: :errors)
```

Error message is optional when adding error : 
```ruby
errors.add(:item, :invalid)
```

is equivalent to
```ruby
errors.add(:item, :invalid, :invalid)
```


## Test with Rspec
Make the spec file `spec/commands/collection_checker_spec.rb` like:

```ruby
describe CollectionChecker do
  subject { described_class.call(collection) }

  describe '.call' do
    context 'when the context is successful' do
      let(:collection) { [1] }
      
      it 'succeeds' do
        is_expected.to be_success
      end
    end

    context 'when the context is not successful' do
      let(:collection) { [] }

      it 'fails' do
        is_expected.to be_failure
      end
    end
  end
end
```

## Mock

To simplify your life, the gem come with mock helper.  
You must include `Command::SpecHelpers::MockCommandHelper`in your code.

### Setup

To allow this, you must require the `spec_helpers` file and include them into your specs files :
```ruby
require 'command/spec_helpers'
describe CollectionChecker do
  include Command::SpecHelpers::MockCommandHelper
  # ...
end
```

or directly in your `spec_helpers` : 
```ruby
require 'command/spec_helpers'
RSpec.configure do |config|
  config.include Command::SpecHelpers::MockCommandHelper
end
```

### Usage

You can mock a command, to be successful or to fail :  
```ruby
describe "#mock_command" do
  subject { mock }
  
  context "to fail" do
    let(:mock) do
      mock_command(CollectionChecker,
        success: false,
        result: nil,
        errors: { collection: [ code: :empty, message: "Your collection is empty !" ] },
      )
    end
    
    it { is_expected.to be_failure }
    it { is_expected.to_not be_success }
    it { expect(subject.errors).to eql({ collection: [ code: :empty, message: "Your collection is empty !" ] }) }
    it { expect(subject.result).to be_nil }
  end
  
  context "to success" do
    let(:mock) do
      mock_command(CollectionChecker,
        success: true,
        result: 10,
        errors: {},
      )
    end
    
    it { is_expected.to_not be_failure }
    it { is_expected.to be_success }
    it { expect(subject.errors).to be_empty }
    it { expect(subject.result).to eql 10 }
  end
end
```

For an unsuccessful command, you can use a simpler mock :
```ruby
let(:mock) do
  mock_unsuccessful_command(CollectionChecker,
    errors: { collection: [ empty:  "Your collection is empty !" ] }
  )
end
```

For a successful command, you can use a simpler mock :
```ruby
let(:mock) do
  mock_successful_command(CollectionChecker,
    result: 10
  )
end
```

## Matchers

To simplify your life, the gem come with matchers.  
You must include `Command::SpecHelpers::CommandMatchers`in your code.

To allow this, you must require the `spec_helpers` file and include them into your specs files :
```ruby
require 'command/spec_helpers'
describe CollectionChecker do
  include Command::SpecHelpers::CommandMatchers
  # ...
end
```

or directly in your `spec_helpers` :
```ruby
require 'command/spec_helpers'
RSpec.configure do |config|
  config.include Command::SpecHelpers::CommandMatchers
end
```

#### Rails project

Instead of above, you can include matchers only for specific classes, using inference 

```ruby
require 'command/spec_helpers'
RSpec::Rails::DIRECTORY_MAPPINGS[:class] = %w[spec classes]
RSpec.configure do |config|
  config.include Command::SpecHelpers::CommandMatchers, type: :class
end
```

### Usage
```ruby
subject { CollectionChecker.call({}) }

it { is_expected.to be_failure }
it { is_expected.to have_failed }
it { is_expected.to have_failed.with_error(:collection, :empty) }
it { is_expected.to have_failed.with_error(:collection, :empty, "Your collection is empty !") }
it { is_expected.to have_error(:collection, :empty) }
it { is_expected.to have_error(:collection, :empty, "Your collection is empty !") }

context "when called in a controller" do
  before { get :index }
  # the 3 matchers bellow are aliases
  it { expect(CollectionChecker).to have_been_called_with_action_controller_parameters(payload) }
  it { expect(CollectionChecker).to have_been_called_with_ac_parameters(payload) }
  it { expect(CollectionChecker).to have_been_called_with_acp(payload) }
end

```
