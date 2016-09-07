module Schlepper
  module AbstractMethodHelper
    def self.included(base)
      base.instance_variable_set :@__abstract_methods__, {}
      base.send :extend, Schlepper::AbstractMethodHelper::ClassMethods
    end

    # @param [Symbol, String] method_name
    # @return [Bool]
    def abstract_method? method_name
      self.class.__abstract_methods__.fetch method_name.to_sym, false
    end

    module ClassMethods
      # Marks a method as 'abstract'. That is, it is not intended to be used
      # without overriding and implementing. Essentially re-defines the method
      # to throw a NotImplementedError if called directly or
      # when subclassed and not overridden.
      # @param [String, Symbol] Name of method to mark as abstract
      # @return [Symbol] Name of method
      def __abstract_methods__
        @__abstract_methods__
      end

      # We want a subclass to know what is abstract or not
      # We DO NOT want to use a class variable as they are shared from
      # all subclasses of the base class.
      # @private
      def inherited subclass
        super
        subclass.instance_variable_set :@__abstract_methods__, @__abstract_methods__.dup
      end

      def abstract method_name
        # this implementation is a little long on purpose to encapsulate
        # all of the logic into one method. we do not want to pollute the destination
        # class, so no extraction techniques are available
        method_name = method_name.to_sym
        @__abstract_methods__.store method_name, true

        instance_eval do
          # undefine any existing method to prevent warnings
          undef_method method_name if method_defined? method_name

          define_method method_name do
            # check to see if the method we are calling is directly on the class
            # that implements the abstract method
            #
            # that is, if A#override_me is implemented as abstract, we want to notify the
            # callee that this method is abstract and can not be called directly
            # otherwise, we want to notify the callee that the subclass
            # needs to implement the abstract method before calling it
            #
            # that is, if B subclasses A and A implements override_me
            # as abstract, then B#override_me should notify the callee that
            # #override_me is declared abstract on A and needs to be overridden
            # on B
            failure_message = (
              if self.class.instance_method(__method__).owner == self.class
              <<-MESSAGE
The method #{method_name} is designated as abstract on #{self.class.name}.
You must subclass #{self.class.name} and override this method yourself.
              MESSAGE
            else
              # now we want the inheritance chain without any inherited modules, and without
              # Object and BasicObject. the returned array looks like [self, D, C, B, A]
              # we want to notify the callee exactly where the method was declared abstract
              # in the chain
              parent_abstract_class = (self.class.ancestors - self.class.included_modules)[1..-3].
                find { |klass| klass.method_defined? method_name }
              <<-MESSAGE
The class #{self.class.name} does not implement the abstract method #{method_name}, which
is declared as abstract on #{parent_abstract_class.name}.
              MESSAGE
              end
            )
            fail NotImplementedError, failure_message
          end
        end

        method_name
      end

      # @private
      def method_added method_name
        # figure out if we are adding a new method from `define_method` above
        # we don't want to mark this is not abstract when overriding the
        # defined method with an abstract definition
        return if caller.grep(/#{__FILE__}/).grep(/define_method/).any?
        if @__abstract_methods__.key?(method_name)
          @__abstract_methods__.store method_name, false
        end
      end
    end
  end
end
