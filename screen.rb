#!/usr/bin/env ruby
# -*- coding: UTF-8 -*-

class Screen
	def initialize(args)
		
	end
	
	
end

class NcursesScreen < Screen
	require "./color.rb"
	require "ncurses"
	include Ncurses
	
	def initialize
		Ncurses.initscr
		Ncurses.curs_set(0)
		Ncurses.cbreak # unbuffered input
		Ncurses.noecho # turn off input echoing
		Ncurses.stdscr.intrflush(false)
		Ncurses.stdscr.keypad(true)
		@screen = Ncurses.stdscr
		init_term_size
		Ncurses.start_color
		Ncurses.use_default_colors
	end

	def init_term_size
		@termwidth = Ncurses.getmaxx(@screen)
		@termheight = Ncurses.getmaxy(@screen)
	end

	def close
		Ncurses.nocbreak
		Ncurses.endwin
	end

	def clear
		@screen.clear
		@screen.refresh
	end

	def get_key
		@screen.getch.chr
	end

	def refresh
		@screen.refresh
	end

	def print_str(str)
		@screen.addstr(str)
	end
	
	
end

class NcursesController
	def initialize(screen)
		@screen = screen.new
	end

	def run
		@reload_file = false
		@screen.clear
		do_run
	end
	
	def close
		@screen.close
	end

	def do_run
		loop do
			line = "Hello Screen!"
			@screen.print_str(line)
			@screen.refresh

			loop do
				ch = @screen.get_key
				case ch
				when 'q'[0], 'Q'[0] # 'Q'uit
					return
				end
			end
		end	
	end
	
end

controller = NcursesController.new(NcursesScreen)
controller.run
controller.close
