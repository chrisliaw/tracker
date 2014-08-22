
class String
	def to_hex
		self.each_byte.map { |b| "%2s" % b.to_s(16) }.join
	end

	def hex_to_bin
		self.scan(/../).map { |x| x.hex.chr }.join
	end
end

Dir.glob("#{File.join(File.dirname(__FILE__),"lib")}/*").each do |f|
	require f
end
