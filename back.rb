require 'prawn'
class BackPDF
	def initialize(options={})
		default_options = {
			:page_size => [612, 792],
			# font options
			:url_font => {:color => '666666', :size => 4, :face => 'GothamMedium'},
			# scaling and positioning parameters
			:assembly_scale => 2,
			:assembly_position => {:x => 100, :y => 100},
			# rotation
			:assembly_rotation => 0
		}
		@options = default_options.merge(options)
		@pdf = Prawn::Document.new(:page_size => @options[:page_size],
			:margin => [0, 0],
			:skip_page_creation => true)

		@pdf.font_families.update("GothamMedium" => {
			:normal => "gothammedium.ttf"})
	end

	def draw_back_assembly(
		options = {}
	)
		options = @options.merge(options)
		module_size = options[:module_size]
		image_width = image_height = module_size
		scale = options[:assembly_scale]
		@pdf.save_graphics_state
		origin = [options[:assembly_position][:x],
			options[:page_size][1] - options[:assembly_position][:y] - image_height*scale]
		@pdf.scale scale
		@pdf.translate (origin[0])/scale.to_f, (origin[1])/scale.to_f
		@pdf.rotate(options[:assembly_rotation], :origin => [0, image_width]) do
			#Draw the image
			x = -0.5*image_width
			y = 1.5*image_height
			
			@pdf.image 'back-color.png', :at => [x, y], :scale => image_width/600.0
	
			@pdf.font_size options[:url_font][:size]
			@pdf.font options[:url_font][:face]
			@pdf.fill_color options[:url_font][:color]
			@pdf.draw_text "www.plickers.com",
				:at => [-0.5*@pdf.width_of("www.plickers.com"), 0.5*image_height - 1.5]

			#@pdf.fill_color '000000'
			#@pdf.fill_rectangle([x, y], module_size, module_size)
		end
		@pdf.restore_graphics_state
	end

	#Generate the PDF and save to disk
	def save(file_name)
		@pdf.render_file file_name
	end

  #TODO draw dashed cutting lines

	def draw_card_set(count, options = {})
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
					{:size => 250, :position => [306, 198]},
					{:size => 250, :position => [306, 594]}
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
					{:size => 250, :position => [414, 198]},
					{:size => 250, :position => [414, 594]}
				]
			},
			# 2/page
			:two_offcenter_left => {
				:assembly_geometries => [
					{:size => 250, :position => [198, 198]},
					{:size => 250, :position => [198, 594]}
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
			:layout_configuration => :two_offcenter_right,
			:assembly_geometries => [
				# TODO: uncomment?
					{:size => 33, :position => [306, 396]}
			],
			:assembly_options => {
				:module_size => 100,
				:assembly_position => {}
			},
			:randomize_rotation => true
		}
		options = default_options.merge(options)

		#if specified, load a layout configuration
		if options[:layout_configuration]
			options = options.merge(layout_configurations[options[:layout_configuration]])
		end

		#number of barcode to print on each page
		assemblies_per_page = options[:assembly_geometries].count

		(1..count).each_with_index do |foo, index|
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

			draw_back_assembly(options[:assembly_options])
		end
	end
end

###Test
barcode = BackPDF.new({:page_size => [612, 792]}) #'LETTER' => [612, 792]

barcode.draw_card_set(40)

#Save to file
barcode.save "backs.pdf"