module Audited
  module Async
    extend ActiveSupport::Autoload
    autoload :Resque
    autoload :Synchronous
  end
end
