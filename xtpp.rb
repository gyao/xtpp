#!/usr/bin/env ruby
# -*- coding: UTF-8 -*-

require "./file_parser.rb"
require "./page.rb"
require "./renders.rb"

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
render = Gutpp::NcrusesRender.new
page_builder = Gutpp::PageBuilder.new(render)
presentation_file = Gutpp::FileParser.new('test.tpp', page_builder)

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