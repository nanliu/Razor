# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

$std_counter = 0

require "project_razor/error/generic"
require "require_all"
require_rel "error/"

module ProjectRazor
  module Error

    @@error_number = 0

    # We use this to automatically generate self incrementing error numbers.
    def self.error_number
      @@error_number += 1
    end

    def self.contantize(val)
      raise TypeError unless val.is_a? String
      val.split('::').reduce(Module, :const_get)
    end

    # This creates additional error classes with appropriate http_err code and log_severity.
    def self.create_class(new_class, val={}, msg='', parent_str='ProjectRazor::Error::Generic')
      raise TypeError unless val.is_a? Hash
      # Make sure we don't specify any instance variable other than what's in Generic Error attr_reader.
      raise Error, "invalid settings #{val.inspect}" unless (val.keys - ['@http_err', '@log_severity']).empty?

      parent = ProjectRazor::Error.contantize(parent_str)
      parent_module_str = parent_str.split('::')[0..-2].join('::')
      parent_module = ProjectRazor::Error.contantize(parent_module_str)

      c = Class.new(parent) do
        val.each do |k, v|
          instance_variable_set(k, v)
        end
        instance_variable_set('@std_err', parent_module.error_number)
        instance_variable_set('@msg', msg)
        def initialize(message)
          super("#{self.class.name} #{message}")
        end
      end

      parent_module.const_set new_class, c
    end

  end
end
