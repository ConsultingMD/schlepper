require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

desc 'Opens a interactive session with this library already loaded'
task :console do
  require 'schlepper'

  begin
    require 'pry'
  rescue
    require 'irb'
  end

  if defined? Pry
    Pry.start
  else
    ARGV.clear
    IRB.start
  end
end

task default: :test
