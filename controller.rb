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

	class NcrusesInteractiveController < BaseController
		def initialize(file_name)
			@file_name = file_name
			@cur_page = 0
		end

		def run
			begin
				@reload_file = false
				renderer = Xtpp::NcrusesRender.new
				page_builder = Xtpp::PageBuilder.new(renderer)
				parser = Xtpp::FileParser.new(@file_name, page_builder)
				parser.parse
				@pages = parser.pages
				@cur_page = @pages.size - 1 if @cur_page >= @pages.size

			end while @reload_file
		end
		
		
	end
end