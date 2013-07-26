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
			:page_size => [612, 792],
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

		@pdf.restore_graphics_state
	end

	#Generate the PDF and save to disk
	def save(file_name)
		@pdf.render_file file_name
	end
	
	def draw_card_set(cards, options = {})
		default_options = {
			:assembly_geometries => [
				 {:size => 50, :position => [310, 396]},
    		 {:size => 50, :position => [400, 500]}
			],
			:assembly_options => {:barcode_size => 100, :assembly_position => {}}
		}
		options = default_options.merge(options)

		#number of barcode to print on each page
		assemblies_per_page = options[:assembly_geometries].count

		cards.keys.each_with_index do |number, index|
			@pdf.start_new_page if index%assemblies_per_page == 0
			on_page_index = index % assemblies_per_page
			assembly_geometry = options[:assembly_geometries][on_page_index]

			scale = assembly_geometry[:size].to_f / options[:assembly_options][:barcode_size]
			options[:assembly_options][:assembly_scale] = scale
			options[:assembly_options][:assembly_position][:x] = assembly_geometry[:position][0]
			options[:assembly_options][:assembly_position][:y] = assembly_geometry[:position][1]
			fills = cards[number]
			options[:assembly_options][:numbers] = [number, number, number, number]
			draw_barcode_assembly(fills, options[:assembly_options])
		end
	end
end

###Test
barcode = BarcodePDF.new({:page_size => [620, 792]})
pages = {"0" => [0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	"1" => [0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	"2" => [0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1,0,0,0,1,0,0,0,0,0]}

barcode.draw_card_set(pages)

#Save to file
barcode.save "test.pdf"