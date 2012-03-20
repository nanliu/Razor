# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "json"
require "yaml"

# Root ProjectRazor namespace
# @author Nicholas Weaver
module ProjectRazor
  module Slice
    # ProjectRazor Slice ImageSvc
    # Used for image management
    # @author Nicholas Weaver
    class Imagesvc < ProjectRazor::Slice::Base
      # Initializes ProjectRazor::Slice::Model including #slice_commands, #slice_commands_help, & #slice_name
      # @param [Array] args
      def initialize(args)
        super(args)
        # Here we create a hash of the command string to the method it corresponds to for routing.
        @slice_commands = {:add => "add_image",
                           :get => "list_images",
                           :default => "list_images"}
        @slice_commands_help = {:add => "imagesvc add " + "[mk|os]".blue + " (PATH TO ISO)".yellow,
                                :get => "imagesvc [get]",
                                :default => "imagesvc [get]"}
        @slice_name = "Imagesvc"
      end

      #Lists images
      def list_images
        if @web_command
          slice_error("CLIOnlySlice", false)
        else
          print_images get_object("images", :images)
        end
      end

      #Add an image
      def add_image
        @command = :add
        setup_data
        image_types = {:mk => {:desc => "MicroKernel ISO", :classname => "ProjectRazor::ImageService::MicroKernel"},
                       :os => {:desc => "OS Install ISO", :classname => "ProjectRazor::ImageService::OSInstall"}}
        if @web_command
          slice_error("CLIOnlySlice", false)
        else

          image_type = @command_array.shift

          unless check_against_types(image_type, image_types)
            print_types(image_types)
            slice_error("InvalidImageType", false)
            return
          end

          iso_path = @command_array.shift
          unless iso_path != nil && iso_path != ""
            slice_error("NoISOProvided", false)
            return
          end

          classname = image_types[image_type.to_sym][:classname]

          new_image = Object::full_const_get(classname).new({})
          res = new_image.add(iso_path, @data.config.image_svc_path)

          unless res[0]
            slice_error(res[1], false)
            return
          end


          unless insert_image(new_image)
            slice_error("CouldNotSaveImage", false)
            return
          end

          puts "\nNew image added successfully\n".green
          print_images [new_image]
        end
      end

      def insert_image(image_obj)
        setup_data
        image_obj = @data.persist_object(image_obj)
        image_obj.refresh_self
      end

      def print_types(types)
        puts "\nPlease select a valid image type.\nValid types are:".red
        types.each_key do
        |k|
          print "\t[#{k}]".yellow
          print " - "
          print "#{types[k][:desc]}".yellow
          print "\n"
        end
      end

      def check_against_types(type,types)
        types.each_key do
        |k|
          return true if type == k.to_s
        end
        false
      end



      # Handles printing of bmc details to CLI or REST
      # @param [Hash] bmc_array
      def print_images(images_array)
        unless @web_command
          puts "Images:"

          unless @verbose
            images_array.each do
            |image|


              print "\tType: "
              print "#{image.description}  ".green
              print "Version: "
              case image.class.to_s

                when "ProjectRazor::ImageService::MicroKernel"

                  print "#{image.iso_version}   ".green
                  print "\n"
                  print "#{image.iso_build_time}   ".green
                  print "\n"
                else
                  # nothing
              end

              print "Filename: "
              print "#{image.filename}   ".green
              print "\n"


              image.set_image_svc_path(@data.config.image_svc_path)
              print "Path: "
              print "#{image.image_path}   ".green
              print "\n"

            end
          else
            images_array.each do
            |image|
              image.instance_variables.each do
              |iv|
                unless iv.to_s.start_with?("@_")
                  key = iv.to_s.sub("@", "")
                  print "#{key}: "
                  print "#{bmc.instance_variable_get(iv)}  ".green
                end
              end
              print "\n"
            end
          end
        else
          images_array = images_array.collect { |image| image.to_hash }
          slice_success(images_array, false)
        end
      end

    end
  end
end
