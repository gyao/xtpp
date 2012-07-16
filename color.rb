module Gutpp
	# Maps color names to constants and indexes.
	class ColorMap

		# Maps color name _color_ to a constant
		def ColorMap.get_color(color)
			colors = { "white" => COLOR_WHITE,
				"yellow" => COLOR_YELLOW,
				"red" => COLOR_RED,
				"green" => COLOR_GREEN,
				"blue" => COLOR_BLUE,
				"cyan" => COLOR_CYAN,
				"magenta" => COLOR_MAGENTA,
				"black" => COLOR_BLACK,
				"default" => -1
			}
			colors[color]
		end

		# Maps color name to a color pair index
		def ColorMap.get_color_pair(color)
			colors = { "white" => 1,
				"yellow" => 2,
				"red" => 3,
				"green" => 4,
				"blue" => 5,
				"cyan" => 6,
				"magenta" => 7,
				"black" => 8, 
				"default" =>-1
			}
			colors[color]
		end
	end

end