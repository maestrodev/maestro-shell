require 'rubygems'
require 'rspec'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib') unless $LOAD_PATH.include?(File.dirname(__FILE__) + '/../lib')

require 'shell'

RSpec.configure do |config|

  config.mock_with :mocha

end



