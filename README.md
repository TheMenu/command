# Command

A simple, standardized way to build and use _Service Objects_ in Ruby.

Table of Contents
=================

* [Command](#command)
* [Table of Contents](#table-of-contents)
* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
    * [Subcommand](#subcommand)
    * [Merge errors from ActiveRecord instance](#merge-errors-from-activerecord-instance)
    * [Error message](#error-message)
* [Test with Rspec](#test-with-rspec)
    * [Mock](#mock)
        * [Setup](#setup)
        * [Usage](#usage-1)
    * [Matchers](#matchers)
        * [Setup](#setup-1)
        * [Rails project](#rails-project)
        * [Usage](#usage-2)


Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

# Requirements

* At least Ruby 2.0+

It is used with Ruby 2.7 and Ruby 3 projects.

# Installation

Add this line to your application's Gemfile:

```ruby
gem 'command', github: 'TheMenu/command'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install command

# Usage

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
        details: command.errors,
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

##  Subcommand

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

## Merge errors from ActiveRecord instance
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

## Stopping execution of the command

To avoid the verbosity of numerous `return` statements, you have three alternative ways to stop the execution of a
command:

### abort
```ruby
class FormatChecker
  prepend Command

  def call
    abort :collection, :failure, "Not an array" unless @collection.is_a?(Array)
    @collection.class.name
  end

  def initialize(collection)
    @collection = collection
  end
end

command = FormatChecker.call("not array")
command.success? # => false
command.failure? # => true
command.errors # => { collection: [ { code: :failure, message: "Not an array" } ] }
```

### assert
```ruby
class UserDestroyer
  prepend Command

  def call
    assert check_if_user_is_destroyable
    @user.destroy!
  end

  def check_if_user_is_destroyable
    errors.add :user, :active, "Can't destroy active users" if @user.projects.active.any?
    errors.add :user, :sole_admin, "Can't destroy last admin" if @user.admin? && User.admin.count == 1
  end
end

invalid_user = User.admin.with_active_projects.first
command = UserDestroyer.call(invalid_user)
command.success? # => false
command.failure? # => true
command.errors # => { user: [
#   { code: :active, message: "Can't destroy active users" },
#   { code: :sole_admin, message: "Can't destroy last admin" }
# ] }
```

### ExitError

Raising an `ExitError` anywhere during `#call`'s execution will stop the command.

## Error message

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

### Default scope

Inside a Command class, you can specify a base I18n scope by calling the class method `#i18n_scope=`, it will be the
default scope used to localize error messages during `errors.add`. Default value is `errors.messages`.

### Example
```yaml
# config/locales/en.yml
en:
  errors:
    messages:
      date:
        invalid: "Invalid date (yyyy-mm-dd)"
      invalid: "Invalid value"
  activerecord:
    messages:
      invalid: "Invalid record"
```

```ruby
# config/locales/en.yml

class CommandWithDefaultScope
  prepend Command

  def call
    errors.add(:generic_attribute, :invalid) # Identical to errors.add(:generic_attribute, :invalid, :invalid)
    errors.add(:date_attribute, :invalid, 'date.invalid')
  end
end
CommandWithDefaultScope.call.errors == {
  generic_attribute: [{ code: :invalid, message: "Invalid value" }],
  date_attribute: [{ code: :invalid, message: "Invalid date (yyyy-mm-dd)" }],
}

class CommandWithCustomScope
  prepend Command

  self.i18n_scope = 'activerecord.messages'

  def call
    errors.add(:base, :invalid) # Identical to errors.add(:base_attribute, :invalid, :invalid)
  end
end
CommandWithCustomScope.call.errors == {
  base: [{ code: :invalid, message: "Invalid record" }],
}
```

# Test with Rspec
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

### Setup

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

### Rails project

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
