module Rspec
  module Schlepper
    class TaskGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('../templates', __FILE__)

      def onetime_script_spec
        template 'onetime_script_spec.rb.erb', "#{::Schlepper::Paths::SPEC_DIR}/#{file_name}_spec.rb"
      end

      def task_name
        file_name.sub(/\A\d+_/, '')
      end

      def require_task_path
        task_dir = Pathname.new(::Schlepper::Paths::TASK_DIR)
        spec_dir = Pathname.new(::Schlepper::Paths::SPEC_DIR)

        "#{task_dir.relative_path_from spec_dir}/#{file_name}"
      end
    end
  end
end
