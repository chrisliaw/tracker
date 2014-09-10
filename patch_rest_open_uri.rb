
# Serves as tools to patch the rest-open-uri gems for it to work

require 'tempfile'

spec = Gem::Specification.find_by_name('rest-open-uri')
dir = spec.gem_dir

target = File.join(dir,"lib","rest-open-uri.rb")
if File.exist?(target)
	tmp = Tempfile.new('tmp_rest-open-uri.rb')
	@cnt = 0
	File.open(target,'r') do |f|
		f.each_line do |l|
			if @cnt == 0
				tmp.puts "# encoding: US-ASCII"
				@cnt = @cnt + 1
			end
			tmp.puts l
		end
	end
	tmp.close
	FileUtils.mv(tmp,target)
end


