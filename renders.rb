module Xtpp
	class BaseRender
		def initialize
			# do nothing
		end
		
		def split_lines(text, width)
			lines = []
			return lines unless text
			begin
				text.lstrip!
				idx = text.length < width ? text.length : ((text.index(" ").nil? or text.index(" ") > width) ? width : text.index(" "))
				lines << text[0..idx - 1]
				text = text[idx..-1]
			end while text.length > 0
			lines
		end

		def self.define_method_for(name)
			define_method(name) {
				$stderr.puts "Error: BaseRender##{name} has been called directly."
				Kernel.exit(1)
			}	
		end

		commands = ["do_footer", "do_header", "do_refresh", "new_page", "do_heading", "do_withborder", "do_horline", "do_color", "do_center", "do_right", "do_exec", "do_wait", "do_beginoutput", "do_beginshelloutput", "do_endoutput", "do_endshelloutput", "do_sleep", "do_boldon", "do_boldoff", "do_revon", "do_revoff", "do_ulon", "do_uloff", "do_beginslideleft", "do_slide", "do_command_prompt", "do_beginslideright", "do_beginslidetop", "do_beginslidebottom", "do_sethugefont", "do_huge", "print_line", "do_title", "do_author", "do_date", "do_bgcolor", "do_fgcolor"]
		commands.each { |command| define_method_for command}

		def rend(line)
			case line
			when /^--heading /
				heading = line.sub(/^--heading /, "")
				do_heading(heading)
			when /^--withborder/
				do_withborder
			when /^--horline/
				do_horline
			when /^--color /
				color = line.sub(/^--color /, "")
				color.strip!
				do_color(color)
			when /^--center /
				text = line.sub(/^--center /, "")
				do_align(:center, text)
			when /^--right /
				text = line.sub(/^--right /, "")
				do_align(:right, text)
			when /^--exec /
				cmdline = line.sub(/^--exec /, "")
				do_exec(cmdline)
			when /^---/
				do_wait
				return true
			when /^--beginoutput/
				do_beginoutput
			when /^--beginshelloutput/
				do_beginshelloutput
			when /^--endoutput/
				do_endoutput
			when /^--endshelloutput/
				do_endshelloutput
			when /^--sleep /
				time2sleep = line.sub(/^--sleep /, "")
				do_sleep(time2sleep)
			when /^--boldon/
				do_boldon
			when /^--boldoff/
				do_boldoff
			when /^--revon/
				do_revon
			when /^--revoff/
				do_revoff
			when /^--ulon/
				do_ulon
			when /^--uloff/
				do_uloff
			when /^--beginslide/
				direction = line.sub(/^--beginslide /, "left")
				do_beginslide(direction)
			when /^--endslide/
				do_endslide
			when /^--sethugefont /
				params = line.sub(/^--sethugefont /, "")
				do_sethugefont(params.strip)
			when /^--huge /
				figlet_text = line.sub(/^--huge /, "")
				do_huge(figlet_text)
			when /^--footer /
				@footer_txt = line.sub(/^--footer /, "")
				do_footer(@footer_txt) 
			when /^--header /
				@header_txt = line.sub(/^--header /, "")
				do_header(@header_txt) 
			when /^--title /
				title = line.sub(/^--title /,"")
				do_title(title)
			when /^--author /
				author = line.sub(/^--author /,"")
				do_author(author)
			when /^--date /
				date = line.sub(/^--date /, "")
				if date == "today" then
					date = Time.now.strftime("%b %d %Y")
				elsif date =~ /^today / then
					date = Time.now.strftime(date.sub(/^today /,""))
				end
				do_date(date)
			when /^--bgcolor /
				color = line.sub(/^--bgcolor /,"").strip
				do_bgcolor(color)
			when /^--fgcolor /
				color = line.sub(/^--fgcolor /,"").strip
				do_fgcolor(color)
			when /^--color /
				color = line.sub(/^--color /,"").strip
				do_color(color)
			else
				print_line(line)
			end
			
			return false
		end
		
	end

	class StdoutRender < BaseRender
		require "./color.rb"
		def initialize
			# do nothing
		end

		def rend(line)
			$stdout.puts "#{line}"
		end
		
	end

	class NcrusesRender < BaseRender
		def initialize
			@figletfont = "standard"
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
			#do_bgcolor("black")
			@fgcolor = ColorMap.get_color_pair("white")
			@voffset = 5
			@indent = 3
			@cur_line = @voffset
			@output = @shelloutput = false
		end

		# implements template methods

		def do_footer(footer_txt)
			@screen.move(@termheight - 3, (@termwidth - footer_txt.length) / 2)
			@screen.addstr(footer_txt)
		end

		def do_header(header_txt)
			@screen.move(@termheight - @termheight+1, (@termwidth - header_txt.length) / 2)
			@screen.addstr(header_txt)
		end

		def do_refresh
			@screen.refresh
		end

		def new_page
			@cur_line = @voffset
			@output = @shelloutput = false
			setsizes
			@screen.clear
		end

		def do_heading(line)
			@screen.attron(Ncurses::A_BOLD)
			print_heading(line)
			@screen.attroff(Ncurses::A_BOLD)
		end

		def do_withborder
			@withborder = true
			draw_border
		end

		def do_horline
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

		def do_exec
			# TODO: implement later
		end

		def do_wait
			# nothing
		end

		def do_beginoutput
			@output = true
			draw_output_border :begin
			@cur_line += 1
		end

		def do_beginshelloutput
			@shelloutput = true
			draw_output_border :begin
			@cur_line += 1
		end

		def do_endoutput
			draw_output_border :end if @output
			@output = false
			@cur_line += 1
		end

		def do_endshelloutput
			draw_output_border :end if @shelloutput
			@shelloutput = false
			@cur_line += 1
		end

		def do_sleep(time2sleep)
			Kernel.sleep(time2sleep.to_i)
		end

		def do_boldon
			@screen.attron(Ncurses::A_BOLD)
		end

		def do_boldoff
			@screen.attroff(Ncurses::A_BOLD)
		end

		def do_revon
			@screen.attron(Ncurses::A_REVERSE)
		end

		def do_revoff
			@screen.attroff(Ncurses::A_REVERSE)
		end

		def do_ulon
			@screen.attron(Ncurses::A_UNDERLINE)
		end

		def do_uloff
			@screen.attroff(Ncurses::A_UNDERLINE)
		end

		def do_beginslide(direction)
			@slideoutput = true
			@slidedir = direction
		end

		def do_endslide
			@slideoutput = false
		end

		def do_sethugefont(params)
			@figletfont = params
		end

		def do_huge(figlet_text)
			output_width = @termwidth - @indent
			output_width -= 2 if @output or @shelloutput
			op = IO.popen("figlet -f #{@figletfont} -w #{output_width} -k \"#{figlet_text}\"","r") # gyao: what's figlet??
			op.readlines.each do |line|
				print_line(line)
			end
			op.close
		end

		def print_line(line)
			width = @termwidth - 2 * @indent
			width -= 2 if @output or @shelloutput
			lines = split_lines(line, width)
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
			do_boldon
			do_align(:center, title)
			do_boldoff
			do_align(:center, "")
		end

		def do_author(author)
			do_align(:center, author)
			do_align(:center, "")
		end

		def do_date(date)
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


		def clear
			@screen.clear
			@screen.refresh
		end

		def setsizes
			@termwidth = Ncurses.getmaxx(@screen)
			@termheight = Ncurses.getmaxy(@screen)
		end
		
	end
end