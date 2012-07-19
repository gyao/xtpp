#!/usr/bin/env ruby
# -*- coding: UTF-8 -*-

require "./file_parser.rb"
require "./page.rb"
require "./renders.rb"
require "./controller.rb"

VERSION_NBR_MAJOR = 0
VERSION_NBR_MINOR = 2

def load_ncurses
	begin
		require "ncurses"
		include Ncurses
	rescue LoadError
		$stderr.print "There is no Ncurses-Ruby package installed which is needed by TPP.\nYou can download it on: http://ncurses-ruby.berlios.de/"
		Kernel.exit(1)
	end
end

load_ncurses
ctrl = Xtpp::InteractiveController.new("test.tpp", Xtpp::NcursesRender)
ctrl.run


#def with_page_break(title)
#	$stdout.puts "---------- Begin Page #{title} ----------"
#	yield
#	$stdout.puts "---------- End of Page #{title} ----------"
#end

#presentation_file.pages.each do |page|
	#with_page_break(page.title) do
#		page.show
	#end
#end