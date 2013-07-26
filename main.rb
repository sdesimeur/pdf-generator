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
			:annotations => ['www.plickers.com', 'plickers v0.1.4p-3', '', ''],
			:answers => ['A', 'B', 'C', 'D'],
			:numbers => ['?', '?', '?', '?'],
			# font options
			:annotation_font => {:color => '555555', :size => 12, :face => 'Helvetica'},
			:answer_font => {:color => '333333', :size => 16, :face => 'Times-Roman'},
			:number_font => {:color => '333333', :size => 32, :face => 'Arial'},
			# text box positions
			:annotation_position => {:x => 10, :y => 10},
			:answer_position => {:x => 0, :y => 10},
			:number_position => {:x => -10, :y => 10},
			# barcode parameters
			:barcode_size => 100,
			:barcode_color => '000000',
			# scaling and positioning parameters
			:assembly_scale => 2,
			:assembly_position => {:x => 100, :y => 100}
		}
		@options = options.merge(default_options)
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

	#Parameters:
	# (Hash) *pages*: an hash that contains fill code for each page
	# => key: page_number
	# => value: fill code
	def draw_barcode_assembly(
		pages #barcode fill-array of all pages
	)
		#draw each page based on the fill codes
		pages.keys.each_with_index do |page_number, index|
			fills = pages[page_number]
			@pdf.scale @scale
			@options[:numbers] = Array.new(4, page_number)
			@pdf.fill_color @options[:barcode_color]
			@pdf.fill_rectangle([0, @height], @width, @height)

			#Draw the empty box
			@pdf.fill_color = "ffffff"
			fills.each_with_index do |value, index|
				if value == 1 #Need to be empty, draw white box
					x = @options[:barcode_size]*FILL_CODE[index][0]
					y = @height - (@options[:barcode_size]*FILL_CODE[index][1])
					@pdf.fill_rectangle([x, y], @options[:barcode_size], @options[:barcode_size])
				end
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
					@pdf.font_size @options[:annotation_font][:size]
					@pdf.font @options[:annotation_font][:face]
					@pdf.fill_color @options[:annotation_font][:color]
					@pdf.draw_text @options[:annotations][i], :at => [@options[:annotation_position][:x], @options[:annotation_position][:y]]

					#draw the answer text
					@pdf.font_size @options[:answer_font][:size]
					@pdf.font @options[:answer_font][:face]
					@pdf.fill_color @options[:answer_font][:color]
					answer = @options[:answers][i]
					@pdf.draw_text answer, 
						:at => [@width/2 - @pdf.width_of(answer) - @options[:answer_position][:x], 
								@options[:answer_position][:y]] 

					#draw the number
					@pdf.font_size @options[:number_font][:size]
					@pdf.font @options[:number_font][:face]
					@pdf.fill_color @options[:number_font][:color]
					number = @options[:numbers][i]
					@pdf.draw_text number, :at => [
						@width - @pdf.width_of(number) + @options[:number_position][:x], 
						@options[:number_position][:y]]
				end
				angle -= 90
				@pdf.restore_graphics_state
			end

			#Check if we need to start a new page or not
			@pdf.start_new_page if index < pages.count - 1
		end
	end

	#Generate the PDF and save to disk
	def save(file_name)
		@pdf.render_file file_name
	end
end

###Test
barcode = BarcodePDF.new
pages = {"0" => [0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	"1" => [0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	"2" => [0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1,0,0,0,1,0,0,0,0,0]}

barcode.draw_barcode_assembly(pages)

#Save to file
barcode.save "test.pdf"