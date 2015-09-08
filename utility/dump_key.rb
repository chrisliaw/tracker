
# intended to run via
# > rails runner dump_key.rb <table name> <output file>
# Dump all unique identifier from the table

if ARGV.length < 2
	STDERR.puts "#{__FILE__} <table name> <output file>"
else
	File.open(ARGV[1],"w") do |f|
		db = eval("#{ARGV[0].classify}")
		db.all.each do |dev|
			f.puts dev.identifier
		end
	end
end

	
