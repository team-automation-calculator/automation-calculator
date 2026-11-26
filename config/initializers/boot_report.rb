require 'boot_report'

# Only when serving requests (`rails s`, which every environment uses):
# rake tasks, the console and the asset precompile in the image build boot
# the app too, and none of them needs the report or the check. In
# production a missing required setting stops the server here; see
# BootReport.boot and AppConfig::REQUIRED.
Rails.application.config.after_initialize do
  BootReport.boot(server: defined?(Rails::Server))
end
