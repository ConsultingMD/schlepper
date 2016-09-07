require 'test_helper'
require 'active_record'
require 'rails'
require 'pry'

class ProcessTest < Minitest::Test
  def setup
    super
    $stdout = StringIO.new
    ActiveRecord::Base.connection.send(start_transaction_method)
    ActiveRecord::Base.connection.increment_open_transactions
  end

  def teardown
    super
    $stdout = @original_stdout
    ActiveRecord::Base.connection.send(end_transaction_method)
    ActiveRecord::Base.connection.decrement_open_transactions
  end

  def start_transaction_method
    if ActiveRecord::VERSION::MAJOR < 4
      :begin_db_transaction
    else
      :rollback_transaction
    end
  end

  def end_transaction_method
    if ActiveRecord::VERSION::MAJOR < 4
      :rollback_db_transaction
    else
      :rollback_transaction
    end
  end

  def initialize(*args)
    super
    @original_stdout = $stdout
    ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
  end

  def test_creates_task_log_table
    Schlepper::Process.new.run_all
    finder_method = if Rails::VERSION::MAJOR >= 5
                      :data_source_exists?
                    else
                      :table_exists?
                    end

    assert ActiveRecord::Base.connection.send(finder_method, 'schlepper_tasks')
  end

  def test_runs_tasks_that_need_processed
    Rails.stub :root, Pathname.new(File.join(File.expand_path(File.dirname(__FILE__)), 'support')) do
      Schlepper::Process.new.run_all
      refute_empty ActiveRecord::Base.connection.exec_query('SELECT version FROM schlepper_tasks').rows
    end
  end
end
