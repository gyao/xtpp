# -*- coding: UTF-8 -*-

module Xtpp
	class BaseRender
		def initialize
			
		end

		def split_lines(text, width)
			$stderr.puts "text: #{text}; width: #{width}"
			lines = []
			return lines unless text
			begin
				text.lstrip!
				idx = text.length < width ? text.length : ((text.index(" ", -1).nil? or text.index(" ", -1) > width) ? width : text.index(" ", -1))
				$stderr.puts "idx: #{idx}"
				lines << text[0..idx - 1]
				text = text[idx..-1]
			end while text.length > 0
			lines
		end

		def self.define_command_method(name)
			define_method(name) do |params|
				$stderr.puts "Error: BaseRender#do_#{name} has been called directly."
				Kernel.exit(1)
			end
		end

		commands = ["footer", "header", "refresh", "heading", "withborder", "horline", "color", "center", "right", "exec", "wait", "beginoutput", "beginshelloutput", "endoutput", "endshelloutput", "sleep", "bold", "reverse", "underline", "beginslide", "endslide", "command_prompt", "sethugefont", "huge", "print_line", "title", "author", "date", "bgcolor", "fgcolor"]
		commands.each { |command| define_command_method "do_#{command}"}

		def render(line, eop)
			$stderr.puts line.end_with? "||"
			matched = ""
			commands = ["footer", "header", "refresh", "heading", "withborder", "horline", "color", "center", "right", "exec", "wait", "beginoutput", "beginshelloutput", "endoutput", "endshelloutput", "sleep", "bold", "reverse", "underline", "beginslide", "endslide", "command_prompt", "sethugefont", "huge", "print_line", "title", "author", "date", "bgcolor", "fgcolor"]
			commands.each do |command|
				matched = $& if Regexp.new("^--#{command}(\s)*") =~ line
			end
			if matched != ""
				method_name = "do_#{matched[2..-1].strip}"
				params = line.sub(Regexp.new("^#{matched}"), "").strip
				self.send(method_name, params)
				return true if method_name == "do_wait"
				return false
			else
				print_line(line)
			end
			return false
		end
		
	end

	class StdoutRender < BaseRender
		def initialize
			# do nothing
		end

		def render(line)
			$stdout.puts "#{line}"
		end
		
	end

	class NcursesRender < BaseRender
		require "./color.rb"
		def initialize
			Ncurses.initscr
			Ncurses.curs_set(0)
			Ncurses.cbreak # unbuffered input
			Ncurses.noecho # turn off input echoing
			Ncurses.stdscr.intrflush(false)
			Ncurses.stdscr.keypad(true)
			@screen = Ncurses.stdscr
			setsizes
			Ncurses.start_color()
			Ncurses.use_default_colors()
			@figletfont = "standard"
			do_bgcolor("black")
			@fgcolor = ColorMap.get_color_pair("white")
			@voffset = 5
			@indent = 3
			@cur_line = @voffset
			@output = @shelloutput = false
		end

		# implements template methods

		def do_footer(footer_txt)
			@footer_txt = footer_txt
			@screen.move(@termheight - 3, (@termwidth - footer_txt.length) / 2)
			@screen.addstr(footer_txt)
		end

		def do_header(header_txt)
			@header_txt = header_txt
			@screen.move(@termheight - @termheight+1, (@termwidth - header_txt.length) / 2)
			@screen.addstr(header_txt)
		end

		def do_refresh(params)
			@screen.refresh
		end

		def do_heading(line)
			@screen.attron(Ncurses::A_BOLD)
			print_heading(line)
			@screen.attroff(Ncurses::A_BOLD)
		end

		def do_withborder(params)
			@withborder = true
			draw_border
		end

		def do_horline(params)
			@screen.attron(Ncurses::A_BOLD)
			@termwidth.times do |x|
				@screen.move(@cur_line, x)
				@screen.addstr("-")
			end
			@screen.attroff(Ncurses::A_BOLD)
		end

		def do_color(color)
			num = ColorMap.get_color_pair(color)
			Ncurses.attron(Ncurses.COLOR_PAIR(num))
		end

		def do_center(text)
			do_align(:center, text)
		end

		def do_right(text)
			do_align(:right, text)
		end

		def do_exec(params)
			# TODO: implement later
		end

		def do_wait(params)
			# nothing
		end

		def do_beginoutput(params)
			@output = true
			draw_output_border :begin
			@cur_line += 1
		end

		def do_beginshelloutput(params)
			@shelloutput = true
			draw_output_border :begin
			@cur_line += 1
		end

		def do_endoutput(params)
			draw_output_border :end if @output
			@output = false
			@cur_line += 1
		end

		def do_endshelloutput(params)
			draw_output_border :end if @shelloutput
			@shelloutput = false
			@cur_line += 1
		end

		def do_sleep(time2sleep)
			Kernel.sleep(time2sleep.to_i)
		end

		def do_bold(switch)
			if switch == "on"
				@screen.attron(Ncurses::A_BOLD)
			else
				@screen.attroff(Ncurses::A_BOLD) # default is turn off, I'm a conservative guy... :)
			end
		end

		def do_reverse(switch)
			if switch == "on"
				@screen.attron(Ncurses::A_REVERSE) 
			else
				@screen.attroff(Ncurses::A_REVERSE)
			end
		end

		def do_underline(switch)
			 if switch == "on"
			 	@screen.attron(Ncurses::A_UNDERLINE)
			 else
				@screen.attroff(Ncurses::A_UNDERLINE)
			end
		end

		def do_beginslide(position)
			@slideoutput = true
			@slidedir = position
		end

		def do_endslide(params)
			@slideoutput = false
		end

		def do_sethugefont(font)
			@figletfont = font
		end

		def do_huge(figlet_text)
			output_width = @termwidth - @indent
			output_width -= 2 if @output or @shelloutput
			op = IO.popen("figlet -f #{@figletfont} -w #{output_width} -k \"#{figlet_text}\"","r")
			op.readlines.each do |line|
				print_line(line)
			end
			op.close
		end

		def print_line(line)
			width = @termwidth - 2 * @indent
			width -= 2 if @output or @shelloutput
			lines = split_lines(line, width)
			$stderr.puts "lines: #{lines}"
			lines.each do |l|
				@screen.move(@cur_line, @indent)
				@screen.addstr("| ") if (@output or @shelloutput) and ! @slideoutput
				
				if @shelloutput and (l =~ /^\$/ or l=~ /^%/ or l =~ /^#/ or l =~ /^>/) then
					type_line(l)
				elsif @slideoutput then
					slide_text(l)
				else
					@screen.addstr(l)
				end
				if (@output or @shelloutput) and ! @slideoutput then
					@screen.move(@cur_line,@termwidth - @indent - 2)
					@screen.addstr(" |")
				end
				@cur_line += 1
			end
		end

		def do_title(title)
			do_bold("on")
			do_align(:center, title)
			do_bold("off")
			do_align(:center, "")
		end

		def do_author(author)
			do_align(:center, author)
			do_align(:center, "")
		end

		def do_date(params)
			date = params
			if date == "today" then
				date = Time.now.strftime("%b %d %Y")
			elsif date =~ /^today / then
				date = Time.now.strftime(date.sub(/^today /,""))
			end
			do_align(:center, date)
			do_align(:center, "")
		end

		def do_bgcolor(color)
			bgcolor = ColorMap.get_color(color) or COLOR_BLACK
			Ncurses.init_pair(1, COLOR_WHITE, bgcolor)
			Ncurses.init_pair(2, COLOR_YELLOW, bgcolor)
			Ncurses.init_pair(3, COLOR_RED, bgcolor)
			Ncurses.init_pair(4, COLOR_GREEN, bgcolor)
			Ncurses.init_pair(5, COLOR_BLUE, bgcolor)
			Ncurses.init_pair(6, COLOR_CYAN, bgcolor)
			Ncurses.init_pair(7, COLOR_MAGENTA, bgcolor)
			Ncurses.init_pair(8, COLOR_BLACK, bgcolor)
			if @fgcolor then
				Ncurses.bkgd(Ncurses.COLOR_PAIR(@fgcolor))
			else
				Ncurses.bkgd(Ncurses.COLOR_PAIR(1))
			end
		end

		def do_fgcolor(color)
			@fgcolor = ColorMap.get_color_pair(color)
			Ncurses.attron(Ncurses.COLOR_PAIR(@fgcolor))
		end

		# controller implementations
		def close
			Ncurses.nocbreak
			Ncurses.endwin
		end

		def clear
			@screen.clear
			@screen.refresh
		end

		def get_key
			ch = @screen.getch
			case ch
			when Ncurses::KEY_RIGHT
				return :keyright
			when Ncurses::KEY_DOWN
				return :keydown
			when Ncurses::KEY_LEFT
				return :keyleft
			when Ncurses::KEY_UP
				return :keyup
			when Ncurses::KEY_RESIZE
				return :keyresize
			else
				return ch.chr
			end
		end

		def store_screen
			@screen.dupwin
		end

		def restore_screen(s)
			Ncurses.overwrite(s, @screen)
		end

		def draw_slidenum(cur_page,max_pages,eop)
			@screen.move(@termheight - 2, @indent)
			@screen.attroff(Ncurses::A_BOLD) # this is bad
			@screen.addstr("[slide #{cur_page}/#{max_pages}]")
			do_footer(@footer_txt) if @footer_txt.to_s.length > 0
			do_header(@header_txt) if @header_txt.to_s.length > 0
			draw_eop_marker if eop
		end

		def do_refresh(params)
			@screen.refresh
		end

		def show_help
			help_text = [ 
				"xtpp help", 
				"",
				"space bar ............................... display next entry within page",
				"space bar, cursor-down, cursor-right .... display next page",
				"b, cursor-up, cursor-left ............... display previous page",
				"q, Q .................................... quit tpp",
				"j, J .................................... jump directly to page",
				"l, L .................................... reload current file",
				"s, S .................................... jump to the first page",
				"e, E .................................... jump to the last page",
				"c, C .................................... start command line",
				"?, h .................................... this help screen" 
			]
			@screen.clear
			y = @voffset
			help_text.each do |line|
				@screen.move(y,@indent)
				@screen.addstr(line)
				y += 1
			end
			@screen.move(@termheight - 2, @indent)
			@screen.addstr("Press any key to return to slide")
			@screen.refresh
		end

		def draw_eop_marker
			@screen.move(@termheight - 2, @indent - 1)
			@screen.attron(A_BOLD)
			@screen.addstr("*")
			@screen.attroff(A_BOLD)
		end

		def new_page
			@cur_line = @voffset
			@output = @shelloutput = false
			setsizes
			@screen.clear
		end

		private

		def print_heading(line)
			width = @termwidth - 2 * @indent
			lines = split_lines(line, width)
			lines.each do | l |
				@screen.move(@cur_line, @indent)
				x = (@termwidth - l.length)/2
				@screen.move(@cur_line, x)
				@screen.addstr(l)
				@cur_line += 1
			end
		end

		def draw_border
			@screen.move(0, 0)
			@screen.addstr(".")
			(@termwidth - 2).times { @screen.addstr("-") }; @screen.addstr(".")
			@screen.move(@termheight - 2,0)
			@screen.addstr("`")
			(@termwidth - 2).times { @screen.addstr("-") }; @screen.addstr("'")
			1.upto(@termheight - 3) do |y|
				@screen.move(y, 0)
				@screen.addstr("|") 
			end
			1.upto(@termheight - 3) do |y|
				@screen.move(y, @termwidth - 1)
				@screen.addstr("|") 
			end
		end

		def draw_output_border(type)
			@screen.move(@cur_line, @indent)
			@screen.addstr(".") if type == :begin
			@screen.addstr("`") if type == :end
			(@termwidth - @indent * 2 - 2).times { @screen.addstr("-") }
			@screen.addstr(".") if type == :begin
			@screen.addstr("'") if type == :end
		end

		def do_align(direction, text)
			width = @termwidth - 2 * @indent
			width -= 2 if @output or @shelloutput
			lines = split_lines(text, width)
			lines.each do |l|
				@screen.move(@cur_line, @indent)
				@screen.addstr(" |") if @output or @shelloutput
				if direction == :center
					x = (@termwidth - l.length) / 2
				elsif direction == :right
					x = (@termwidth - l.length - 5)
				end
				@screen.move(@cur_line, x)
				@screen.addstr(l)
				if @output or @shelloutput
					@screen.move(@cur_line, @termwidth - @indent - 2) if direction == :center
					@screen.addstr(" |")
				end
				@cur_line += 1
			end
		end

		def type_line(l)
			l.each_byte do |x|
				@screen.addstr(x.chr)
				@screen.refresh()
				r = rand(20)
				time_to_sleep = (5 + r).to_f / 250;
				Kernel.sleep(time_to_sleep)
			end
		end

		def slide_text(l)
			return if l == ""
			case @slidedir
			when "left"
				xcount = l.length-1
				while xcount >= 0
					@screen.move(@cur_line,@indent)
					@screen.addstr(l[xcount..l.length-1])
					@screen.refresh()
					time_to_sleep = 1.to_f / 20
					Kernel.sleep(time_to_sleep)
					xcount -= 1
				end	
			when "right"
				(@termwidth - @indent).times do |pos|
					@screen.move(@cur_line,@termwidth - pos - 1)
					@screen.clrtoeol()
					maxpos = (pos >= l.length-1) ? l.length-1 : pos
					@screen.addstr(l[0..pos])
					@screen.refresh()
					time_to_sleep = 1.to_f / 20
					Kernel.sleep(time_to_sleep)
				end # do
			when "top"
				# ycount = @cur_line
				new_scr = @screen.dupwin
				1.upto(@cur_line) do |i|
					Ncurses.overwrite(new_scr,@screen) # overwrite @screen with new_scr
					@screen.move(i,@indent)
					@screen.addstr(l)
					@screen.refresh()
					Kernel.sleep(1.to_f / 10)
				end
			when "bottom"
				new_scr = @screen.dupwin
				(@termheight-1).downto(@cur_line) do |i|
					Ncurses.overwrite(new_scr,@screen)
					@screen.move(i,@indent)
					@screen.addstr(l)
					@screen.refresh()
					Kernel.sleep(1.to_f / 10)
				end
			end
		end

		def setsizes
			@termwidth = Ncurses.getmaxx(@screen)
			@termheight = Ncurses.getmaxy(@screen)
		end
		
	end
end