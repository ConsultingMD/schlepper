module Schlepper
  class TaskGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)

    def onetime_script
      @now = Time.now
      template 'onetime_script.rb.erb', "#{Paths::TASK_DIR}/#{timestamped_task_name}.rb"
    end

    def stringified_timestamp
      @now.strftime '%Y%m%d%H%M%S'
    end

    def timestamped_task_name
      "#{stringified_timestamp}_#{file_name}"
    end

    hook_for :test_framework, as: 'schlepper:task' do |instance, test_generator|
      instance.invoke test_generator, [instance.timestamped_task_name]
    end
  end
end
