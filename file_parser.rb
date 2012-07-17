# -*- coding: UTF-8 -*-

module Xtpp
	class FileParser
		def initialize(file_name, page_builder)
			@file_name = file_name
			@page_builder = page_builder
			@pages = []
		end

		def parse
			begin
				f = File.open(@file_name, :encoding => 'UTF-8')
			rescue 
				$stderr.puts "Error: couldn't open file: #{$!}"
				Kernel.exit(1)
			end

			n_pages = 0
			cur_page = @page_builder.build("slide #{n_pages + 1}".to_s)

			f.each_line do | line |
				line.chomp!
				case line
				when /^--##/ # ignore comments
				when /^--newpage/
					@pages << cur_page
					n_pages += 1
					name = line.sub(/^--newpage/, "")
					if name == "" then
						name = "slide #{n_pages + 1}".to_s
					else
						name.strip!
					end
					cur_page = @page_builder.build(name)
				else
					cur_page.line = line
				end
			end
			@pages << cur_page
		end

		def pages
			@pages
		end
	end
end
