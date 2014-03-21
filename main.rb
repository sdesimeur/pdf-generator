require 'prawn'
class BarcodePDF
	MODULES_PER_SIDE = 5
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
			:annotations => ['www.plickers.com', 'version 1', '', ''],
			:answers => ['A', 'B', 'C', 'D'],
			:numbers => ['?', '?', '?', '?'],
			:names => ['', '', '', ''],
			# font options
			:annotation_font => {:color => 'cccccc', :size => 14, :face => 'GothamNarrowMedium'},
			:answer_font => {:color => '999999', :size => 28, :face => 'GothamNarrowBook'},
			:number_font => {:color => '999999', :size => 28, :face => 'GothamNarrowBook'},
			:name_font => {:color => '999999', :size => 24, :face => 'GothamNarrowBook'},
			# text box positions
			:annotation_position => {:x => 6, :y => 10},
			:answer_position => {:x => 0, :y => 10},
			:number_position => {:x => -6, :y => 10},
			:name_position => {:x => 6, :y => 10},
			# barcode parameters
			:module_size => 100,
			:zero_module_color => '111111',
			:one_module_color => 'ffffff',
			# scaling and positioning parameters
			:assembly_scale => 2,
			:assembly_position => {:x => 100, :y => 100},
			# rotation
			:assembly_rotation => 0
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
		@pdf.font_families.update("GothamNarrowBook" => {
			:normal => "gothamnarrowbook.ttf"})
		@pdf.font_families.update("GothamNarrowMedium" => {
			:normal => "gothamnarrowmedium.ttf"})
		@pdf.font_families.update("GothamNarrowBold" => {
			:normal => "gothamnarrowbold.ttf"})
	end

	def draw_barcode_assembly(
		fills, options = {} #barcode fill-array
	)
		options = @options.merge(options)
		module_size = options[:module_size]
		barcode_width = barcode_height = module_size * MODULES_PER_SIDE
		scale = options[:assembly_scale]
		@pdf.save_graphics_state
		origin = [options[:assembly_position][:x],
			options[:page_size][1] - options[:assembly_position][:y] - barcode_height*scale]
		@pdf.scale scale
		@pdf.translate (origin[0])/scale.to_f, (origin[1])/scale.to_f
		@pdf.rotate(options[:assembly_rotation], :origin => [0, barcode_width]) do
			#Draw the boxes
			fills.each_with_index do |value, index|
				x = module_size*(FILL_CODE[index][0] - 2.5)
				y = barcode_height - (module_size*(FILL_CODE[index][1] - 2.5))

				if value == 1 #Need to be empty, draw white box
					@pdf.fill_color = options[:one_module_color]
				else
					@pdf.fill_color options[:zero_module_color]
				end
				@pdf.fill_rectangle([x, y], module_size, module_size)
			end

			#Draw 4 sides
			angle = 0
			translate_x = [0, barcode_width, barcode_width, 0]
			translate_y = [barcode_height, barcode_height, 0, 0]
			4.times do |i|
				@pdf.save_graphics_state
				@pdf.translate(translate_x[i] - barcode_width/2.0, translate_y[i] + barcode_height/2.0)
				@pdf.rotate(angle, :origin => [0, 0]) do

					#draw the answer text
					@pdf.font_size options[:answer_font][:size]
					@pdf.font options[:answer_font][:face]
					@pdf.fill_color options[:answer_font][:color]
					answer = options[:answers][i]
					@pdf.draw_text answer,
						:at => [barcode_width/2 - @pdf.width_of(answer)/2 - options[:answer_position][:x],
								options[:answer_position][:y]]

					answer_width = @pdf.width_of(answer)

					if options[:name].empty?

						#draw the annotation text
						@pdf.font_size options[:annotation_font][:size]
						@pdf.font options[:annotation_font][:face]
						@pdf.fill_color options[:annotation_font][:color]
						@pdf.draw_text options[:annotations][i],
							:at => [options[:annotation_position][:x], options[:annotation_position][:y]]

						#draw the number
						@pdf.font_size options[:number_font][:size]
						@pdf.font options[:number_font][:face]
						@pdf.fill_color options[:number_font][:color]
						@pdf.default_leading = 0
						number = options[:numbers][i].to_s
						width = @pdf.width_of(number)
						font_size = options[:number_font][:size]

						while width > barcode_width/2 - answer_width/2 - 20
							font_size -= 1
							width = @pdf.width_of(number, :size => font_size, :single_line => true)
						end

						@pdf.draw_text number,
							:at => [barcode_width - width + options[:number_position][:x],
							options[:number_position][:y]],
							:size => font_size

					else

						#draw the name
						@pdf.font_size options[:name_font][:size]
						@pdf.font options[:name_font][:face]
						@pdf.fill_color options[:name_font][:color]
						@pdf.default_leading = 0
						name = options[:name]
						width = @pdf.width_of(name)
						font_size = options[:name_font][:size]

						while width > barcode_width/2 - answer_width/2 - 40 # TODO: 40 here should be a parameter
							font_size -= 1
							width = @pdf.width_of(name, :size => font_size, :single_line => true)
						end

						@pdf.draw_text name,
							:at => [options[:name_position][:x],
											options[:name_position][:y]],
								:size => font_size

						#draw the number
						@pdf.font_size options[:number_font][:size]
						@pdf.font options[:number_font][:face]
						@pdf.fill_color options[:number_font][:color]
						@pdf.default_leading = 0
						number = options[:numbers][i].to_s
						number_width = @pdf.width_of(number)
						font_size = options[:number_font][:size]

						while number_width > barcode_width/2 - answer_width/2 - 20 # TODO: 20 here should be a parameter
							font_size -= 1
							number_width = @pdf.width_of(number, :size => font_size, :single_line => true)
						end

						@pdf.draw_text number,
							:at => [barcode_width - number_width + options[:number_position][:x],
							options[:number_position][:y]],
							:size => font_size

						#draw the annotation text
						@pdf.font_size options[:annotation_font][:size]
						@pdf.font options[:annotation_font][:face]
						@pdf.fill_color options[:annotation_font][:color]
						annotation = options[:annotations][i]
						annotation_width = @pdf.width_of(annotation)
						@pdf.draw_text annotation,
							:at => [barcode_width*3/4 - annotation_width/2,
											options[:annotation_position][:y]]

					end
				end
				angle -= 90
				@pdf.restore_graphics_state
			end

		end

		@pdf.restore_graphics_state
	end

	#Generate the PDF and save to disk
	def save(file_name)
		@pdf.render_file file_name
	end

  #TODO draw dashed cutting lines

	def draw_card_set(cards, options = {})
		layout_configurations = {
			# Centered:
			# 1/page
			:one_centered => {
				:assembly_geometries => [
					{:size => 100, :position => [306, 396]}
				]
			},
			# 2/page
			:two_centered => {
				:assembly_geometries => [
					{:size => 50, :position => [306, 198]},
					{:size => 50, :position => [306, 594]}
				]
			},
			# 4/page
			:four_centered => {
				:assembly_geometries => [
					{:size => 40, :position => [153, 198]},
					{:size => 40, :position => [459, 198]},
					{:size => 40, :position => [153, 594]},
					{:size => 40, :position => [459, 594]}
				]
			},
			# Off-center (to minimize cutting):
			# 1/page
			:one_offcenter => {
				:assembly_geometries => [
					{:size => 100, :position => [306, 306]}
				]
			},
			# 2/page
			:two_offcenter_right => {
				:assembly_geometries => [
					{:size => 50, :position => [414, 198]},
					{:size => 50, :position => [414, 594]}
				]
			},
			# 2/page
			:two_offcenter_left => {
				:assembly_geometries => [
					{:size => 50, :position => [198, 198]},
					{:size => 50, :position => [198, 594]}
				]
			},
			# 4/page
			:four_offcenter => {
				:assembly_geometries => [
					{:size => 40, :position => [153, 153]},
					{:size => 40, :position => [459, 153]},
					{:size => 40, :position => [153, 459]},
					{:size => 40, :position => [459, 459]}
				]
			}
		}
		default_options = {
			:layout_configuration => :two_centered,
			:assembly_geometries => [
				# TODO: uncomment?
					{:size => 33, :position => [306, 396]}
			],
			:assembly_options => {
				:module_size => 100,
				:assembly_position => {}
			},
			:randomize_rotation => true,
			:print_names => false
		}
		options = default_options.merge(options)

		#if specified, load a layout configuration
		if options[:layout_configuration]
			options = options.merge(layout_configurations[options[:layout_configuration]])
		end

		cards_collated = []
		if(false) #collate option
			(1..cards.count).each do |number|
				if(number%2 == 1)
					cards_collated << cards[number/2]
				else
					cards_collated << cards[number/2 + 19]
				end
			end
		else
			cards_collated = cards
		end

		#number of barcode to print on each page
		assemblies_per_page = options[:assembly_geometries].count

		cards_collated.each_with_index do |card, index|
			puts card, index
			@pdf.start_new_page if index%assemblies_per_page == 0
			on_page_index = index % assemblies_per_page
			assembly_geometry = options[:assembly_geometries][on_page_index]

			scale = assembly_geometry[:size].to_f / options[:assembly_options][:module_size]
			options[:assembly_options][:assembly_scale] = scale
			options[:assembly_options][:assembly_position][:x] = assembly_geometry[:position][0]
			options[:assembly_options][:assembly_position][:y] = assembly_geometry[:position][1]

			if(options[:randomize_rotation])
				options[:assembly_options][:assembly_rotation] = Random.rand(4)*90
			else
				options[:assembly_options][:assembly_rotation] = 0
			end

			name = ''
			fills = card[:bits]
			number = card[:number]
			name = card[:name] if options[:print_names]
			options[:assembly_options][:numbers] = [number, number, number, number]
			options[:assembly_options][:name] = name
			draw_barcode_assembly(fills, options[:assembly_options])
		end
	end
end

###Test
barcode = BarcodePDF.new({:page_size => [612, 792]}) #'LETTER' => [612, 792]
cards = [
  {:name => "Albert", :number => 0, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]},
  {:name => "Ben", :number => 1, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]},
  {:name => "Cameron", :number => 2, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]},
  {:name => "Doug", :number => 3, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]},
  {:name => "Evelyn", :number => 4, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]},
  {:name => "Frank", :number => 5, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]},
  {:name => "George", :number => 6, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]},
  {:name => "Hector", :number => 7, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]},
  {:name => "Idalia", :number => 8, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]},
  {:name => "Juan", :number => 9, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]},
  {:name => "Katie", :number => 10, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]},
  {:name => "Lisa", :number => 11, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]},
  {:name => "Madeline", :number => 12, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0]},
  {:name => "Noah", :number => 13, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0]},
  {:name => "Oscar", :number => 14, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0]},
  {:name => "Paul", :number => 15, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0]},
  {:name => "Quentin", :number => 16, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]},
  {:name => "Robert", :number => 17, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]},
  {:name => "Susan", :number => 18, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]},
  {:name => "Thomas", :number => 19, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]},
  {:name => "Ursula", :number => 20, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0]},
  {:name => "Veronica", :number => 21, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0]},
  {:name => "Whitney", :number => 22, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0]},
  {:name => "Xander", :number => 23, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0]},
  {:name => "Yolanda", :number => 24, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0]},
  {:name => "Zero", :number => 25, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0]},
  {:name => "Adam Applegate", :number => 26, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0]},
  {:name => "Andrew Boston", :number => 27, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0]},
  {:name => "Alfred Chestertonson", :number => 28, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0]},
  {:name => "Anne Douglas", :number => 29, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0]},
  {:name => "Allie Eberhard", :number => 30, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0]},
  {:name => "Alex Filligree", :number => 31, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0]},
  {:name => "Abraham Geventereaux", :number => 32, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]},
  {:name => "Alexandra Huffington", :number => 33, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]},
  {:name => "", :number => 34, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]},
  {:name => "AJ", :number => 35, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]},
  {:name => "", :number => 36, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0]},
  {:name => "Blankety Blank Blankensonship", :number => 37, :bits => [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0]},
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

barcode.draw_card_set(cards[1..40])

#Save to file
barcode.save "test.pdf"