
#if $0 == __FILE__
	if RUBY_PLATFORM == "java"
		# jruby
		require "#{File.join(File.dirname(__FILE__),"jruby","ancal_jruby")}"
	else
		# native ruby
		require "#{File.join(File.dirname(__FILE__),"ruby","ancal_ruby")}"
	end
#end
