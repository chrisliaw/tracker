
module VCSProvider
	module GitProvider
		Branch = Proc.new do |vcs_path,workspace,branch_id|
			if vcs_path != nil and not vcs_path.empty?
			else
				raise VCSException, "Given VCS path in branch operation is nil or empty. Branch halted", caller
			end

			if Dir.exist?(workspace)
			else
				raise VCSException, "Given workspace #{workspace} in branch operation does not exist. Branch halted", caller
			end

			`cd #{workspace} && #{vcs_path} checkout `
		end
	end
end
