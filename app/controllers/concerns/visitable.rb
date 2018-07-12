module Visitable
  extend ActiveSupport::Concern

  protected

  def current_user_or_visitor
    user_signed_in? ? current_user : current_visitor
  end

  def current_visitor
    Visitor.find(session[:visitor_id]) if session[:visitor_id].present?
  end

  def store_current_visitor(visitor)
    session[:visitor_id] = visitor.id
  end

  def clear_current_visitor
    session.delete :visitor_id
  end
end
