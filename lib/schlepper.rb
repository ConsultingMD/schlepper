module Schlepper
  if defined? Rails::Railtie
    require_relative './schlepper/railtie'
  end

  autoload :VERSION, 'schlepper/version'
  autoload :Process, 'schlepper/process'
  autoload :Task, 'schlepper/task'
  autoload :AbstractMethodHelper, 'schlepper/abstract_method_helper'
end
