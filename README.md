# Schlepper
[![Code Climate](https://codeclimate.com/repos/57cf60bd8ffd8f13f100096b/badges/31af7643bb2adb58ccb7/gpa.svg)](https://codeclimate.com/repos/57cf60bd8ffd8f13f100096b/feed)
[![Test Coverage](https://codeclimate.com/repos/57cf60bd8ffd8f13f100096b/badges/31af7643bb2adb58ccb7/coverage.svg)](https://codeclimate.com/repos/57cf60bd8ffd8f13f100096b/coverage)
[![Build Status](https://travis-ci.org/ConsultingMD/schlepper.svg?branch=master)](https://travis-ci.org/ConsultingMD/schlepper)

_Schlepper: a person who carries, a task runner_

A gem for running and keeping track of one time tasks in a Rails application. Tasks
are versioned and tracked much like Rails migrations.

The purpose of Schlepper is to provide an alternative to onetime data tasks inside migrations, while
offering the conventions, convenience and tracking like Rails migrations.

## Requirements

Rails 3.2+

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'schlepper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install schlepper

## Usage

Schlepper comes with a generator for creating a new task, and a Rake task that will
run any pending onetime tasks.

To create a new onetime task, run `rails generate schlepper:task name_of_task`; where name\_of\_task
follows the same pattern as the Rails' migration generator. Here, a new file is created in `script/schleppers`
that looks like `numerictimestamp_name_of_task.rb`. These also follow the same pattern as Rails' migrations.

Edit the file that was generated and you see a class has been created with some methods for you to
override:

```ruby
class NameOfTask < Schlepper::Task
  USE_TRANSACTION = true

  attr_reader :failure_message

  # @return [String] A short note on what the purpose of this task is
  def description
    <<-DOC.strip_heredoc
      Add your documentation here.
    DOC
    fail NotImplementedError, "Documentation has not been added for #{self.class.name}"
  end

  # @return [String] The individuals that are responsible for this task
  def owner
    "John Bjön"
    fail NotImplementedError, "Ownership has not been claimed for #{self.class.name}"
  end

  # This is the entry point for your task. The full Rails stack is available.
  # Return true if it was successful, false if not. If not successful,
  # set @failure_message to something meaningful. Tasks that return false
  # will not be marked as run and will be continue to be run in subsequent
  # batch runs
  # @return [Bool] Success or failure
  def run

  end
end
```

These methods are self-explanatory. The generator places a failure inside the required methods to ensure that
there is nothing overlooked. The `owner` and `description` methods are utilized in the task running
process to insert that information into the database.

The entry point for the task is in the `run` method. Take special note of the meaning of the return value
of the `run` method. You must return a literal `true` to signal to the task runner that this task
has completed successfully. Any return value other than `true` will signal to the task runner
that this task has not completed successfully, and will not be marked as successful.

The class constant `USE_TRANSACTION` is optional and defaults to `true`. If set to `false`, the task
won't run in a transaction, and returning false will not roll anything back.

Also take note of the instance variable `@failure_message`. Setting this to something
descriptive if your task fails provides meaningful output to the person running the task.

Use `rake schlepper:run` to start the task running process. The task running procedure is as follows:

- Load the Rails app, the `schlepper:run` task inherits from `environment`
- Create the schlepper\_tasks table if it does not exist
- Select all of the version numbers from the schlepper\_tasks table
- Load all task files that have not yet been run
- For each task file
  - Begin a database transaction
  - Create a new instance of the Task class defined in the file
  - Execute the `run` method of that class
  - If the return value of `run` is true
    - Commit the transaction
    - Insert into the schlepper\_tasks table the owner, description, and
      verison of the tasks
  - Otherwise
    - Roll back transaction
    - Display the name of the owner, and @failure\_message if provided

The transaction steps are skipped if `USE_TRANSACTION` is `false`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ConsultingMD/schlepper.

## License

Schlepper is released under the [MIT License](https://opensource.org/licenses/MIT).

## TODO

Implement saving the change registry by providing some back-ends.

Implement rolling back a task
