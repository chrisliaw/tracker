
# intended to be run via
# > rails runner record_check.rb 
# Dump all record count of all models defined in rails db

Dir[Rails.root.to_s + '/app/models/**/*.rb'].each do |file| 
  begin
    require file
  rescue
  end
end

models = ActiveRecord::Base.subclasses.collect { |type| type.name }.sort
models.each do |m|
	print "#{m} : \t"
	begin
		eval("puts #{m.classify}.all.count")
	rescue NameError
		eval("puts #{m.classify}s.all.count")
	end
end
#
#models.each do |model|
#  print model
#  print '  '
#end



