
# intended to run via 
# > rails runner compare.rb <src file> <dest file>
# to compare different Develement from two different node

if ARGV.length < 2

else
	src = ARGV[0]
	dest = ARGV[1]

	@src = []
	File.readlines(src).each do |ln|
		@src << ln
	end

	File.readlines(dest).each do |ln|
		if not @src.include?(ln)
			p ln
			rec = Develement.where(["identifier = ?",ln])
			p rec
		end
	end
end
