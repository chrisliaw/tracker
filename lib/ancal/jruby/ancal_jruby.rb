
Dir.glob("#{File.join(File.dirname(__FILE__),"lib")}/*").each do |f|
	require f
end
