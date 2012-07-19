#!/usr/bin/env ruby
# -*- coding: UTF-8 -*-

require "./file_parser.rb"
require "./page.rb"
require "./renders.rb"
require "./controller.rb"

VERSION_NBR_MAJOR = 0
VERSION_NBR_MINOR = 7

def load_ncurses
	begin
		require "ncurses"
		include Ncurses
	rescue LoadError
		$stderr.print "There is no Ncurses-Ruby package installed which is needed by TPP.\nYou can download it on: http://ncurses-ruby.berlios.de/"
		Kernel.exit(1)
	end
end

def usage
	$stderr.puts "usage: #{$0} <file>\n"
	$stderr.puts "\t -v\t--version\tprint the version"
	$stderr.puts "\t -h\t--help\t\tprint this help"
	Kernel.exit(1)
end

# main program starts here

input = nil
ARGV.each_index do |i|
	if ARGV[i] == '-v' or ARGV[i] == '--version' then
		printf "xtpp - extended text presentation program %s.%s\n", VERSION_NBR_MAJOR, VERSION_NBR_MINOR
		Kernel.exit(1)
	elsif ARGV[i] == '-h' or ARGV[i] == '--help' then
		usage
	elsif input == nil then
		input = ARGV[i]
	end
end

if input == nil then
	usage
end

load_ncurses
ctrl = Xtpp::InteractiveController.new(input, Xtpp::NcursesRender)
ctrl.run
ctrl.close
