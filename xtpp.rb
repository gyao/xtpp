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
renderer = Xtpp::NcrusesRender.new
page_builder = Xtpp::PageBuilder.new(renderer)
presentation_file = Xtpp::FileParser.new('test.tpp', page_builder)

def with_page_break(title)
	$stdout.puts "---------- Begin Page #{title} ----------"
	yield
	$stdout.puts "---------- End of Page #{title} ----------"
end

presentation_file.parse

presentation_file.pages.each do |page|
	#with_page_break(page.title) do
		page.show
	#end
end


#render = Gutpp::BaseRender.new
#p render.split_lines("text to split this isaverylongstringthatexceedswidth", 4)
#p render.split_lines_old("text to split this isaverylongstringthatexceedswidth", 4)
#render.do_footer
#p render.methods