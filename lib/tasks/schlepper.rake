namespace :schlepper do
  desc 'Run all pending Schlepper tasks'
  task run: :environment do
    Schlepper::Process.new.run_all
  end
end
