module Gutpp
	class Page
		def initialize(title, render)
			@title = title
			@render = render
			@lines = []
			@cur_line = 0
			@eop = false # eop means end of page
		end
		
		def line=(a_line)
			@lines << a_line if a_line
		end

		def next_line
			line = @lines[@cur_line]
			@cur_line += 1
			@eop = true if @cur_line >= @lines.size
			line
		end

		def eop?
			@eop
		end

		def reset_eop
			@cur_line = 0
			@eop = false
		end

		def lines
			@lines
		end

		def title
			@title
		end

		def show
			@lines.each { | line | @render.rend(line) }
		end
		
	end

	class PageBuilder
		def initialize(render)
			@render = render
		end
		
		def build(title)
			Page.new(title, @render)
		end
		
	end
end