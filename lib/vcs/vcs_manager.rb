
require "#{File.join(File.dirname(__FILE__),"git","git.rb")}"

class VCSException < Exception; end
DVCSBranch = VCSProvider::GitProvider::Branch
