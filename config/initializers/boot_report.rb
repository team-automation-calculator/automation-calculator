require 'boot_report'

# Only when serving requests (`rails s`, which every environment uses):
# rake tasks, the console and the asset precompile in the image build boot
# the app too, and none of them needs the report.
Rails.application.config.after_initialize do
  BootReport.log if defined?(Rails::Server)
end
