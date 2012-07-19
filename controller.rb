# -*- coding: UTF-8 -*-

module Xtpp
	class BaseController
		def initialize
			$stderr.puts "Error: Cannot initialize Xtpp::BaseController directly!"
			Kernel.exit(1)
		end
		
		def run
			$stderr.puts "Error: Cannot call Xtpp::BaseController::run directly!"
			Kernel.exit(1)
		end

		def close
			$stderr.puts "Error: Cannot call Xtpp::BaseController::close directly!"
			Kernel.exit(1)
		end
		
	end

	class InteractiveController < BaseController
		def initialize(file_name, renderer_name)
			@file_name = file_name
			@renderer = renderer_name.new
			@cur_page = 0
		end

		def close
			@renderer.close
		end

		def run
			begin
				@reload_file = false
				parser = Xtpp::FileParser.new(@file_name)
				parser.parse
				@pages = parser.pages
				@cur_page = @pages.size - 1 if @cur_page >= @pages.size
				@renderer.clear
				@renderer.new_page
				do_run
			end while @reload_file
		end

		private

		def do_run
			loop do
				wait = false
				@renderer.draw_slidenum(@cur_page + 1, @pages.size, false)
				# read and visualize lines until the visualizer says "stop" or we reached end of page
				begin
					line = @pages[@cur_page].next_line
					eop = @pages[@cur_page].eop?
					wait = @renderer.render(line, eop)
				end while not wait and not eop
				
				# draw slide number on the bottom left and redraw:
				@renderer.draw_slidenum(@cur_page + 1, @pages.size, eop)
				@renderer.refresh

				# read a character from the keyboard
				# a "break" in the when means that it breaks the loop, i.e. goes on with visualizing lines
				loop do
					ch = @renderer.get_key
					case ch
					when 'q'[0], 'Q'[0] # 'Q'uit
						return
					when 'r'[0], 'R'[0] # 'R'edraw slide
						changed_page = true # @todo: actually implement redraw
					when 'e'[0], 'E'[0]
						@cur_page = @pages.size - 1
						break
					when 's'[0], 'S'[0]
						@cur_page = 0
						break
					when 'j'[0], 'J'[0] # 'J'ump to slide
						screen = @renderer.store_screen
						p = @renderer.read_newpage(@pages,@cur_page)
						if p >= 0 and p < @pages.size
							@cur_page = p
							@pages[@cur_page].reset_eop
							@renderer.new_page
						else
							@renderer.restore_screen(screen)
						end
						break
					when 'l'[0], 'L'[0] # re'l'oad current file
						@reload_file = true
						return
					when 'c'[0], 'C'[0] # command prompt
						screen = @renderer.store_screen
						@renderer.do_command_prompt
						@renderer.clear
						@renderer.restore_screen(screen)
					when '?'[0], 'h'[0]
						screen = @renderer.store_screen
						@renderer.show_help
						ch = @renderer.get_key
						@renderer.clear
						@renderer.restore_screen(screen)
					when :keyright, :keydown, ' '[0]
						if @cur_page + 1 < @pages.size and eop then
							@cur_page += 1
							@pages[@cur_page].reset_eop
							@renderer.new_page
						end
						break
					when 'b'[0], 'B'[0], :keyleft, :keyup
						if @cur_page > 0 then
							@cur_page -= 1
							@pages[@cur_page].reset_eop
							@renderer.new_page
						end
						break
					when :keyresize
						@renderer.setsizes
					end
				end
			end # loop	
		end
				
	end
end