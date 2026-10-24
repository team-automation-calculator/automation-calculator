# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile +=
  %w[landing_page.js automation_scenarios.js]

Rails.application.config.assets.paths <<
  Rails.root.join('vendor/assets/fonts')

# Dart Sass (dartsass-sprockets) deprecation warnings: hide the ~300 that come
# from bootstrap 4.6's own SCSS (color-functions, global-builtin, if-function,
# @import inside the gem) because they are not actionable before Bootstrap 5.
# The five `@import` warnings from app/assets/stylesheets/application.scss are
# deliberately left visible; they go away when Bootstrap 5 allows `@use`.
Rails.application.config.sass.quiet_deps = true
