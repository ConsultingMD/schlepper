require 'active_support/core_ext/string'
require 'rails'
require 'active_record'

class NoTransaction < Schlepper::Task
  attr_reader :failure_message

  def controls_transaction?
    false
  end

  # @return [String] A short note on what the purpose of this task is
  def description
    <<-DOC.strip_heredoc
      No doc
    DOC
  end

  # @return [String] The individuals that owns this task
  def owner
    "John Bjön"
  end

  # This is the entry point for your script. The full Rails stack is available.
  # Return true if it was successful, false if not. If not successful,
  # set @failure_message to something meaningful. Tasks that return false
  # will not be marked as run and will be continue to be run in subsequent
  # batch runs
  # @return [Bool] Success or failure
  def run
    ActiveRecord::Base.connection.create_table :not_deleted do |table|
      table.string :name
    end
    false
  end
end
