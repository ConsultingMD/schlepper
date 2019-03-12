require 'rails'
require 'active_record'

module Schlepper
  class Process
    def run_all
      old_sync = STDOUT.sync
      STDOUT.sync = true
      create_table_if_necessary
      fetch_script_numbers_from_database
      load_tasks_that_need_run

      puts "#{Schlepper::Task.children.count} tasks to process"
      puts '~~~~~~~~~~~~~~~~~~~~~'

      Schlepper::Task.children.each { |klass| process_one klass }
    rescue => e
      offending_file = e.send(:caller_locations).first.path.split("/").last
      puts "#{offending_file} caused an error: "
      raise e
    ensure
      STDOUT.sync = old_sync
    end

    private def create_table_if_necessary
      # table_exists? changes behavior in Rails 5.1
      finder_method = if ActiveRecord::VERSION::MAJOR >= 5
                        :data_source_exists?
                      else
                        :table_exists?
                      end
      create_script_table unless ActiveRecord::Base.connection.send(finder_method, 'schlepper_tasks')
    end

    private def create_script_table
      migrator_class = ActiveRecord::Migration

      # Rails 5 adds ActiveRecord::Migration.[] to specify an exact migration version
      if migrator_class.respond_to? :[]
        migrator_class = migrator_class["#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"]
      end

      migrator = Class.new(migrator_class) do
        def change
          create_table :schlepper_tasks, id: false do |t|
            t.string :version
            t.string :owner
            t.text :description
            t.datetime :completed_at
          end
        end

        # stop migration output
        def announce(*); end
        def say(*); end
      end

      migrator.migrate :up
    end

    private def fetch_script_numbers_from_database
      @versions ||= ActiveRecord::Base.
        connection.
        exec_query('SELECT version FROM schlepper_tasks').
        map { |r| [r.fetch('version').to_s, true] }.to_h
    end

    private def load_tasks_that_need_run
      Dir.glob("#{Rails.root}/#{Paths::TASK_DIR}/*.rb").
        map { |f| File.basename(f) }.
        sort.
        reject { |f| f.scan(/\A(\d{10,})/).empty? }.
        reject { |f| @versions.has_key?(f.scan(/\A(\d{10,})/).first.first) }.
        each { |f| require File.join(Rails.root, 'script', 'schleppers', f) }
    end

    private def process_one klass
      task = klass.new

      puts ''
      puts "Processing #{klass.name} from #{task.owner}:"
      puts "#{task.description}"
      puts ''

      if task.controls_transaction?
        status = run_task_for task
        log_error(klass.name, task.failure_message, task.owner) unless status
      else
        ActiveRecord::Base.transaction do
          status = run_task_for task
          unless status
            log_error(klass.name, task.failure_message, task.owner)
            fail ActiveRecord::Rollback
          end
        end
      end

      puts ''
      puts "Finished #{klass.name}"
      puts '~~~~~~~~~~~~~~~~~~~~~'
    end

    private def run_task_for(task)
      status = task.run

      if status
        ActiveRecord::Base.connection.execute <<-SQL
          INSERT INTO schlepper_tasks (version, owner, description, completed_at)
          VALUES (
            #{task.version_number},
            #{ActiveRecord::Base.connection.quote(task.owner)},
            #{ActiveRecord::Base.connection.quote(task.description.truncate(256, separator: ' '))},
            #{ActiveRecord::Base.connection.quote(Time.now.to_s(:db))}
          );
        SQL
      end

      status
    end

    private def log_error(name, message, owner)
      puts "#{name} ran without errors, but was not successful"
      if message
        puts "The resulting failure was: #{message}"
      else
        puts "The failure message was not set. Find #{owner} to help investigate"
      end
    end
  end
end
