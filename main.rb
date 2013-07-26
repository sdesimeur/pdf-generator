require 'prawn'
class BarcodePDF
	BARCODE_SIZE = 5
	FILL_CODE = [
		[2, 2], [2, 3], [1, 3], [1, 2], [1, 1], 
		[2, 1], [3, 1], [3, 2], [3, 3], [3, 4], 
		[2, 4], [1, 4],	[0, 4], [0, 3], [0, 2], 
		[0, 1], [0, 0], [1, 0], [2, 0], [3, 0], 
		[4, 0], [4, 1], [4, 2], [4, 3], [4, 4]
	]
	def initialize(options={})
		default_options = {
			:page_size => [612, 792],
			# strings to print (one for each side)
			:annotations => ['www.plickers.com', 'plickers v0.1.4p-3', '', ''],
			:answers => ['A', 'B', 'C', 'D'],
			:numbers => ['?', '?', '?', '?'],
			# font options
			:annotation_font => {:color => 'cccccc', :size => 12, :face => 'Helvetica'},
			:answer_font => {:color => '999999', :size => 16, :face => 'Helvetica'},
			:number_font => {:color => '999999', :size => 32, :face => 'Helvetica'},
			# text box positions
			:annotation_position => {:x => 0, :y => 10},
			:answer_position => {:x => 0, :y => 10},
			:number_position => {:x => 0, :y => 10},
			# barcode parameters
			:barcode_size => 100,
			:barcode_color => '181818',
			# scaling and positioning parameters
			:assembly_scale => 2,
			:assembly_position => {:x => 100, :y => 100}
		}
		@options = default_options.merge(options)
		@margin = [0, 0]
		@pdf = Prawn::Document.new(:page_size => @options[:page_size], 
			:margin => [0, 0],
			:skip_page_creation => true)

		#Update font families
		#Prawn only supports some fonts:
		# Courier Helvetica Times-Roman Symbol ZapfDingbats
	  # Courier-Bold Courier-Oblique Courier-BoldOblique
	  # Times-Bold Times-Italic Times-BoldItalic
	  # Helvetica-Bold Helvetica-Oblique Helvetica-BoldOblique
		@pdf.font_families.update("Arial" => { 
    	:normal => "arial.ttf"})
	end

	def draw_barcode_assembly(
		fills, options = {} #barcode fill-array
	)
		options = @options.merge(options)
		barcode_size = options[:barcode_size]
		@width = @height = barcode_size * BARCODE_SIZE
		scale = options[:assembly_scale]
		@pdf.save_graphics_state
		origin = [options[:assembly_position][:x],
			options[:page_size][1] - options[:assembly_position][:y] - @height*scale]
		@pdf.scale scale
		@pdf.translate (origin[0])/scale.to_f, (origin[1])/scale.to_f
		#Draw the boxes
		fills.each_with_index do |value, index|
			x = barcode_size*(FILL_CODE[index][0] - 2.5)
			y = @height - (barcode_size*(FILL_CODE[index][1] - 2.5))
			
			if value == 1 #Need to be empty, draw white box
				@pdf.fill_color = "ffffff"
			else
				@pdf.fill_color options[:barcode_color]
			end
			@pdf.fill_rectangle([x, y], barcode_size, barcode_size)
		end

		#Draw 4 sides
		angle = 0
		translate_x = [0, @width, @width, 0]
		translate_y = [@height, @height, 0, 0]
		4.times do |i|
			@pdf.save_graphics_state
			@pdf.translate(translate_x[i] - @width/2.0, translate_y[i] + @height/2.0)
			@pdf.rotate(angle, :origin => [0, 0]) do 

				#draw the annotation text
				@pdf.font_size options[:annotation_font][:size]
				@pdf.font options[:annotation_font][:face]
				@pdf.fill_color options[:annotation_font][:color]
				@pdf.draw_text options[:annotations][i], 
				:at => [options[:annotation_position][:x], options[:annotation_position][:y]]

				#draw the answer text
				@pdf.font_size options[:answer_font][:size]
				@pdf.font options[:answer_font][:face]
				@pdf.fill_color options[:answer_font][:color]
				answer = options[:answers][i]
				@pdf.draw_text answer, 
					:at => [@width/2 - @pdf.width_of(answer)/2 - options[:answer_position][:x], 
							options[:answer_position][:y]] 

				answer_width = @pdf.width_of(answer)

				#draw the number
				@pdf.font_size options[:number_font][:size]
				@pdf.font options[:number_font][:face]
				@pdf.fill_color options[:number_font][:color]
				@pdf.default_leading = 0
				number = options[:numbers][i].to_s
				width = @pdf.width_of(number)
				font_size = options[:number_font][:size]
				
				while width > @width/2 - answer_width/2 - 20
					font_size -= 1
					width = @pdf.width_of(number, :size => font_size, :single_line => true)
				end

				@pdf.draw_text number,
					:at => [@width - width + options[:number_position][:x], 
					options[:number_position][:y]],
					:size => font_size
			end
			angle -= 90
			@pdf.restore_graphics_state
		end

		@pdf.restore_graphics_state
	end

	#Generate the PDF and save to disk
	def save(file_name)
		@pdf.render_file file_name
	end
	

  #TODO draw dashed cutting lines

	def draw_card_set(cards, options = {})
		default_options = {
			:assembly_geometries => [
				# {:size => 100, :position => [306, 396]}
				# {:size => 50, :position => [198, 198]},
				# {:size => 50, :position => [198, 594]}
				{:size => 40, :position => [153, 153]},
				{:size => 40, :position => [459, 153]},
				{:size => 40, :position => [153, 459]},
				{:size => 40, :position => [459, 459]}
			],
			:assembly_options => {:barcode_size => 100, :assembly_position => {}}
		}
		options = default_options.merge(options)

		#number of barcode to print on each page
		assemblies_per_page = options[:assembly_geometries].count

		cards.each_with_index do |card, index|
			@pdf.start_new_page if index%assemblies_per_page == 0
			on_page_index = index % assemblies_per_page
			assembly_geometry = options[:assembly_geometries][on_page_index]

			scale = assembly_geometry[:size].to_f / options[:assembly_options][:barcode_size]
			options[:assembly_options][:assembly_scale] = scale
			options[:assembly_options][:assembly_position][:x] = assembly_geometry[:position][0]
			options[:assembly_options][:assembly_position][:y] = assembly_geometry[:position][1]
			fills = card[:bits]
			number = card[:number]
			options[:assembly_options][:numbers] = [number, number, number, number]
			draw_barcode_assembly(fills, options[:assembly_options])
		end
	end
end

###Test
barcode = BarcodePDF.new({:page_size => [612, 792]}) #'LETTER' => [612, 792]
cards = [
  {:name => "A", :number => 0, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]},
  {:name => "B", :number => 1, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]},
  {:name => "C", :number => 2, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]},
  {:name => "D", :number => 3, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]},
  {:name => "E", :number => 4, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]},
  {:name => "F", :number => 5, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]},
  {:name => "G", :number => 6, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]},
  {:name => "H", :number => 7, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]},
  {:name => "I", :number => 8, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]},
  {:name => "J", :number => 9, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]},
  {:name => "K", :number => 10, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]},
  {:name => "L", :number => 11, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]},
  {:name => "M", :number => 12, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0]},
  {:name => "N", :number => 13, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0]},
  {:name => "O", :number => 14, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0]},
  {:name => "P", :number => 15, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0]},
  {:name => "Q", :number => 16, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]},
  {:name => "R", :number => 17, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]},
  {:name => "S", :number => 18, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]},
  {:name => "T", :number => 19, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]},
  {:name => "U", :number => 20, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0]},
  {:name => "V", :number => 21, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0]},
  {:name => "W", :number => 22, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0]},
  {:name => "X", :number => 23, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0]},
  {:name => "Y", :number => 24, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0]},
  {:name => "Z", :number => 25, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0]},
  {:name => "AA", :number => 26, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0]},
  {:name => "AB", :number => 27, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0]},
  {:name => "AC", :number => 28, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0]},
  {:name => "AD", :number => 29, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0]},
  {:name => "AE", :number => 30, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0]},
  {:name => "AF", :number => 31, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0]},
  {:name => "AG", :number => 32, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]},
  {:name => "AH", :number => 33, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]},
  {:name => "AI", :number => 34, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]},
  {:name => "AJ", :number => 35, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]},
  {:name => "AK", :number => 36, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0]},
  {:name => "AL", :number => 37, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0]},
  {:name => "AM", :number => 38, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0]},
  {:name => "AN", :number => 39, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0]},
  {:name => "AO", :number => 40, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0]},
  {:name => "AP", :number => 41, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0]},
  {:name => "AQ", :number => 42, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0]},
  {:name => "AR", :number => 43, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0]},
  {:name => "AS", :number => 44, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0]},
  {:name => "AT", :number => 45, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0]},
  {:name => "AU", :number => 46, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0]},
  {:name => "AV", :number => 47, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0]},
  {:name => "AW", :number => 48, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0]},
  {:name => "AX", :number => 49, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0]},
  {:name => "AY", :number => 50, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0]},
  {:name => "AZ", :number => 51, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0]},
  {:name => "BA", :number => 52, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0]},
  {:name => "BB", :number => 53, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0]},
  {:name => "BC", :number => 54, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0]},
  {:name => "BD", :number => 55, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0]},
  {:name => "BE", :number => 56, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0]},
  {:name => "BF", :number => 57, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0]},
  {:name => "BG", :number => 58, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0]},
  {:name => "BH", :number => 59, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0]},
  {:name => "BI", :number => 60, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0]},
  {:name => "BJ", :number => 61, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0]},
  {:name => "BK", :number => 62, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0]},
  {:name => "BL", :number => 63, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0]}
]

barcode.draw_card_set(cards)

#Save to file
barcode.save "test.pdf"