# Slight modifications from the default Resque tasks
namespace :apn do
  task :setup
  task :work => :sender
  task :workers => :senders

  desc "Start an APN worker"
  task :sender => [ :preload, :setup ] do
    require 'resque'
    require 'apn'

    worker = APN::Sender.new(:full_cert_path => ENV['FULL_CERT_PATH'], :cert_path => ENV['CERT_PATH'], :environment => ENV['ENVIRONMENT'], :cert_pass => ENV['CERT_PASS'])
    worker.verbose = ENV['LOGGING'] || ENV['VERBOSE']
    worker.very_verbose = ENV['VVERBOSE']

    puts "*** Starting worker to send apple notifications in the background from #{worker}"

    worker.work(ENV['INTERVAL'] || 5) # interval, will block
  end

  desc "Start multiple APN workers. Should only be used in dev mode."
  task :senders do
    threads = []

    ENV['COUNT'].to_i.times do
      threads << Thread.new do
        system "rake apn:work"
      end
    end

    threads.each { |thread| thread.join }
  end
  
  # Preload app files if this is Rails
  task :preload => :setup do
    if defined?(Rails) && Rails.respond_to?(:application)
      # Rails 3
      Rails.application.eager_load!
    elsif defined?(Rails::Initializer)
      # Rails 2.3
      $rails_rake_task = false
      Rails::Initializer.run :load_application_classes
    end
  end
end