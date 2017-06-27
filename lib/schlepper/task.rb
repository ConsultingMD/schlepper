module Schlepper
  # Tasks live in your rails app under /script/tasks. They have the same filename
  # pattern as rails migrations, {version time stamp}_class_name.rb
  # A functional generator is provided using `rails generate schlepper:task name_of_task`
  class Task
    include Schlepper::AbstractMethodHelper

    @children = []

    def self.children
      @children
    end

    def self.inherited obj
      super
      children.push obj
    end

    # @return [Fixnum] The version number of the current class
    def version_number
      # We have to find the actual file where the class is defined which is the reason for
      # the method source location weirdness
      @version_number ||= File.basename(method(:run).source_location.first).scan(/\A(\d{10,})/).first.first
    end

    # Signals to the task runner that this task will control its own transaction.
    # When true the task runner will not open a transaction.
    # Use with caution.
    # @return [Boolean]
    def controls_transaction?
      false
    end

    # @return [String] Short note on the intent of this script
    # @abstract
    abstract def description
    end

    # @return [String] Name of the person or people who have ownership of the script
    # @abstract
    abstract def owner
    end

    # This is the entry point for your script. The full Rails stack is available.
    # Return true if it was successful, false if not. If not successful,
    # set @failure_message to something meaningful. Runs that return false
    # will not be marked as run and will be continue to be run in subsequent
    # batch runs
    # @return [Bool] Success or failure
    # @abstract
    abstract def run
    end
  end
end
