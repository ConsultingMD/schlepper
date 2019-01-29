namespace :schlepper do
  desc 'Run all pending Schlepper tasks'
  task run: :environment do
    Schlepper::Process.new.run_all
  end

  task run_one: :environment do
    Schlepper::Process.new.run_single_task ENV.fetch('SCHLEPPER_VERSION')
  end
end
