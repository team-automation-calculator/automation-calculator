module BootstrapHelper
  def bootstrap_class_for(key)
    bootstrap_classes = %w[success info warning danger]

    type = key.to_s if bootstrap_classes.include? key.to_s

    "alert-#{type || 'info'}"
  end
end
