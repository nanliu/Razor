#!/usr/bin/env rspec
require 'spec_helper'

describe ProjectRazor::SliceUtil::Common do

  class TestClass
  end

  before :each do
    @test = TestClass.new
    @test.extend(ProjectRazor::SliceUtil::Common)
  end

  it "should validate_arg" do
    [ nil, {}, '', '{}', '{1}', ['', 1], [nil, 1], ['{}', 1] ].each do |val|
      @test.validate_arg(*[val].flatten).should == false
    end
    @test.validate_arg('foo','bar').should == ['foo', 'bar']
  end

end
