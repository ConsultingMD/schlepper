require 'test_helper'

class SchlepperTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Schlepper::VERSION
  end
end
