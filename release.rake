require 'rake'

task :default,[:ver] => %w[vcs_release]

desc "Create VCS linked release"
task :vcs_release, [:ver] => :set_version

desc "Set version number to indicate release version"
task :set_version, [:ver] do |t, args|
	@newCont = []
	src = File.join(File.dirname(__FILE__),"app","controllers","application_controller.rb")
	IO.readlines(src).each do |line|
		if (line =~ /VER/) == 0
			@newCont << "VER=\"#{args[:ver]}\"\n"
		else
			@newCont << line
		end
	end
	File.open(src,"w") do  |f|
		f.write @newCont.join
	end
end
