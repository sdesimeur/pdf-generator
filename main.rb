require 'prawn'
class BarcodePDF
	BARCODE_SIZE = 5
	FILL_CODE = [
		[2, 2], [3, 2], [3, 1], [2, 1], [1, 1], 
		[1, 2], [1, 3], [2, 3], [3, 3], [4, 3], 
		[4, 2], [4, 1],	[4, 0], [3, 0], [2, 0], 
		[1, 0], [0, 0], [0, 1], [0, 2], [0, 3], 
		[0, 4], [1, 4], [2, 4], [3, 4], [4, 4]
	]
	def initialize(options={})
		default_options = {
			# strings to print (one for each side)
			:annotations => ['test1', 'test2', 'test3', 'test4'],
			:answers => ['A', 'B', 'C', 'D'],
			:numbers => ['?', '?', '?', '?'],
			# font options
			:annotation_font => {:color => 'cccccc', :size => 12, :face => 'Helvetica'},
			:answer_font => {:color => '999999', :size => 16, :face => 'Helvetica'},
			:number_font => {:color => '999999', :size => 32, :face => 'Helvetica'},
			# text box positions
			:annotation_position => {:x => 10, :y => 10},
			:answer_position => {:x => 0, :y => 10},
			:number_position => {:x => -10, :y => 10},
			# barcode parameters
			:barcode_size => 100,
			:barcode_color => '333333',
			# scaling and positioning parameters
			:assembly_scale => 0.75,
			:assembly_position => {:x => 100, :y => 100}
		}
		@options = default_options.merge(options)
		@scale = @options[:assembly_scale]
		@width = @height = @options[:barcode_size] * BARCODE_SIZE
		@margin = [@options[:assembly_position][:x], 
			@options[:assembly_position][:y]]
		@pdf = Prawn::Document.new(:page_size => [(@width + @margin[0]*2)*@scale, (@height + @margin[0]*2)*@scale], :margin => @margin)

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
		barcode_size = @options[:barcode_size]
		options = @options.merge(options)
		@pdf.scale @scale
		
		#Draw the boxes
		fills.each_with_index do |value, index|
			x = barcode_size*FILL_CODE[index][0]
			y = @height - (barcode_size*FILL_CODE[index][1])
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
			@pdf.translate(translate_x[i], translate_y[i])
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
					:at => [@width/2 - @pdf.width_of(answer)/2 + options[:answer_position][:x], 
							options[:answer_position][:y]] 

				#draw the number
				@pdf.font_size options[:number_font][:size]
				@pdf.font options[:number_font][:face]
				@pdf.fill_color options[:number_font][:color]
				number = options[:numbers][i]
				@pdf.draw_text number, :at => [
					@width - @pdf.width_of(number) + options[:number_position][:x], 
					options[:number_position][:y]]
			end
			angle -= 90
			@pdf.restore_graphics_state
		end
	end

	#Generate the PDF and save to disk
	def save(file_name)
		@pdf.render_file file_name
	end
	
	def draw_card_set(pages)
		count = 0
		pages.each do |key, value|
			draw_barcode_assembly(value, {:numbers => [key, key, key, key]})
			if count < pages.keys.length - 1
				@pdf.start_new_page
			end
			count += 1
		end
	end
end

###Test
barcode = BarcodePDF.new
pages = {"Nolan Amy" => [0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	"Stuart Johnson" => [0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	"Clint McBride" => [0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1,0,0,0,1,0,0,0,0,0]}

barcode.draw_card_set(pages)

#Save to file
barcode.save "test2.pdf"