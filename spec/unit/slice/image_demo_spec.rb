#!/usr/bin/env rspec
require 'spec_helper'

require 'project_razor/cli'
require 'project_razor/slice/image_demo'

describe ProjectRazor::Slice::ImageDemo do
  describe 'when parsing command options' do
    it 'should raise error when no commands provided.' do
      image = ProjectRazor::Slice::ImageDemo.new([])

      expect{ image.parse_command! }.to raise_error(ProjectRazor::Error::Slice::InvalidCommand)
    end

    output = $stdout

    it 'should print help if no commands provided.' do
      args = ['imagedemo']
      image = ProjectRazor::Slice::ImageDemo.new([])
      ProjectRazor::Slice::ImageDemo.should_receive(:new).with(args).and_return(image)
      cli = ProjectRazor::Cli.new(args, output)
      cli.should_receive(:error).with { |e, opts|
        e.message.should =~ /Missing slice command/
      }
      cli.run.should == 1
    end

    it 'should print add commands options when non provided.' do
      args = ['imagedemo', 'add']
      sargs = args[1..args.size]
      image = ProjectRazor::Slice::ImageDemo.new(sargs)
      ProjectRazor::Slice::ImageDemo.should_receive(:new).with(sargs).and_return(image)
      cli = ProjectRazor::Cli.new(args, output)
      cli.should_receive(:error).with { |e, slice|
        e.message.should =~ /Missing slice option/
        slice.opts.should =~ /Valid images types/
      }
      cli.run
    end

    #it 'should invoke commands options when non provided.' do
    #  args = ['path']
    #  image = ProjectRazor::Slice::ImageDemo.new(args)
    #  opts = image.opts
    #  opts.banner.should == "Usage: \e[31mrazor image [add|get|path|remove]\e[0m"
    #  image.should_receive(:help)
    #  image.web_command = true
    #  image.run
    #end
  end
end
