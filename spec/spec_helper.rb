require 'rubygems'
require 'rspec'
require 'maestro_plugin/logging_stdout'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib') unless $LOAD_PATH.include?(File.dirname(__FILE__) + '/../lib')

require 'maestro_shell'

RSpec.configure do |config|

  config.mock_with :mocha

end



