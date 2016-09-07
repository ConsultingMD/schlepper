require 'test_helper'
require 'tempfile'

class TaskTest < Minitest::Test
  def teardown
    super
    Schlepper::Task.instance_variable_set :@children, []
  end

  def test_registers_a_subclass
    klass = Class.new(Schlepper::Task)
    assert_includes Schlepper::Task.children, klass
  end

  def test_implements_required_methods
    script = Class.new(Schlepper::Task).new

    %i(description owner run).each do |method_name|
      assert script.respond_to?(method_name), "Schlepper::Task does not implement the #{method_name} method"
    end
  end

  def test_required_methods_are_abstract_on_base
    script = Class.new(Schlepper::Task).new

    %i(description owner run).each do |method|
      assert_raises(NotImplementedError) {script.send method }
    end
  end

  def test_extracts_proper_version_number_from_file
    version_number = Kernel.rand(10_000_000_000).to_s.ljust(10, '0')
    test_file = Tempfile.new ["#{version_number}_version_number", '.rb']
    test_file.write "class TaskTest::VersionNumber < Schlepper::Task; def run; end; end;"
    test_file.rewind
    require test_file.path
    script = TaskTest::VersionNumber.new
    assert_equal version_number, script.version_number
  ensure
    if defined? TaskTest::VersionNumber
      TaskTest.send :remove_const, :VersionNumber
    end
    test_file.close
    test_file.unlink
  end
end
