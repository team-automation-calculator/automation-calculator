module ApplicationHelper
  FLASH_ALERT_CLASSES = {
    'notice' => 'alert-success',
    'alert' => 'alert-danger'
  }.freeze

  # Bootstrap 4 contextual class for a flash type.
  def flash_alert_class(type)
    FLASH_ALERT_CLASSES.fetch(type.to_s, 'alert-info')
  end
end
