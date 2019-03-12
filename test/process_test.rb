require 'test_helper'
require 'active_record'
require 'rails'
require 'pry'

class ProcessTest < Minitest::Test
  def setup
    super
    $stdout = StringIO.new
    ActiveRecord::Base.connection.send(start_transaction_method)
    if ActiveRecord::VERSION::MAJOR < 4
      ActiveRecord::Base.connection.increment_open_transactions
    end
  end

  def teardown
    super
    $stdout = @original_stdout
    ActiveRecord::Base.connection.send(end_transaction_method)
    if ActiveRecord::VERSION::MAJOR < 4
      ActiveRecord::Base.connection.decrement_open_transactions
    end
  end

  def start_transaction_method
    if ActiveRecord::VERSION::MAJOR < 4
      :begin_db_transaction
    else
      :begin_transaction
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

  def finder_method
    if Rails::VERSION::MAJOR >= 5
      :data_source_exists?
    else
      :table_exists?
    end
  end

  def test_creates_task_log_table
    Schlepper::Process.new.run_all
    assert ActiveRecord::Base.connection.send(finder_method, 'schlepper_tasks')
  end

  def test_runs_tasks_that_need_processed
    stub_rails_root_to 'valid_task' do
      Schlepper::Process.new.run_all
      refute_empty ActiveRecord::Base.connection.exec_query('SELECT version FROM schlepper_tasks').rows
    end
  end

  def test_failed_task_with_failure_message
    stub_rails_root_to 'failed_task' do
      assert_output(/boop/) do
        Schlepper::Process.new.run_all
      end
    end
  end

  def test_failed_task_without_failure_message
    stub_rails_root_to 'failed_task_no_message' do
      assert_output(/noname/) do
        Schlepper::Process.new.run_all
      end
    end
  end

  def test_valid_task_too_long_description_ok
    stub_rails_root_to 'valid_task_too_long_description' do
      # We're really just expecting it not to raise an exception when recording it in the DB.
      assert_output(/wackamöle /) do
        Schlepper::Process.new.run_all
      end
    end
  end

  def test_does_not_rollback_no_transaction_task
    stub_rails_root_to 'no_transaction_task' do
      Schlepper::Process.new.run_all
      assert ActiveRecord::Base.connection.send(finder_method, :not_deleted)
    end
  end

  private def stub_rails_root_to fixture_path
    Rails.stub :root, Pathname.new(File.join(File.expand_path(File.dirname(__FILE__)), 'support', fixture_path)) do
      yield
    end
  end
end
