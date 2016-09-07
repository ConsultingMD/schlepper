require_relative './test_helper'
require 'pry'

class AbstractMethodHelperTest < Minitest::Test
  class AbstractBaseClass
    include Schlepper::AbstractMethodHelper

    abstract def override_me; end;
  end

  class BaseSubclass < AbstractBaseClass
  end

  class OverriddenBaseSubclass < AbstractBaseClass
    def override_me
      true
    end
  end

  def test_cannot_call_base_abstract_method
    ex = assert_raises(NotImplementedError) { AbstractBaseClass.new.override_me }
    assert_includes ex.message,
      "You must subclass AbstractMethodHelperTest::AbstractBaseClass and override this method yourself."
  end

  def test_cannot_call_subclassed_abstract_method
    ex = assert_raises(NotImplementedError) { BaseSubclass.new.override_me }

    # we want to assert the full message, that is ensure that we are saying that AbstractBaseClass
    # designated override_me as abstract, and it needs to be overridden in BaseSubclass
    assert_includes ex.message,
      "The class AbstractMethodHelperTest::BaseSubclass does not implement the abstract method override_me, which\nis declared as abstract on AbstractMethodHelperTest::AbstractBaseClass.\n"
  end

  def test_base_class_marks_as_abstract
    assert AbstractBaseClass.new.abstract_method? :override_me
  end

  def test_subclass_marks_as_abstract
    assert BaseSubclass.new.abstract_method? :override_me
  end

  def test_overriden_class_is_not_marked_abstract
    refute OverriddenBaseSubclass.new.abstract_method? :override_me
  end

  def test_can_call_overridden_method
    assert OverriddenBaseSubclass.new.override_me
  end
end
