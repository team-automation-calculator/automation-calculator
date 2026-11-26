require 'boot_report'

# Only when serving requests (`rails s`, which every environment uses):
# rake tasks, the console and the asset precompile in the image build boot
# the app too, and none of them needs the report. In production it logs
# each unset setting at ERROR or WARN and the server keeps serving; see
# BootReport.boot and AppConfig.
Rails.application.config.after_initialize do
  BootReport.boot(server: defined?(Rails::Server))
end
