module VersionChecker
  module_function
  
  def newer?(v1, v2)
    compare_versions(v1, v2) > 0
  end

  def newer_or_equal?(v1, v2)
    compare_versions(v1, v2) >= 0
  end

	def older?(v1, v2)
		!newer_or_equal?(v1, v2)
	end

	def equal?(v1, v2)
		compare_versions(v1, v2) == 0
	end

  private

  def compare_versions(new_version, current_version)
		# Input validation
		return false if new_version.nil? || current_version.nil?
		return false if new_version.to_s.strip.empty? || current_version.to_s.strip.empty?
		return false if new_version == current_version
		
		begin
			# Parse version components (handles pre-release identifiers)
			new_parts = parse_version_parts(new_version)
			current_parts = parse_version_parts(current_version)
			
			# Compare main version numbers first
			version_comparison = compare_version_numbers(new_parts[:numbers], current_parts[:numbers])
			return version_comparison > 0 if version_comparison != 0
			
			# If main versions are equal, compare pre-release identifiers
			compare_prerelease(new_parts[:prerelease], current_parts[:prerelease]) > 0
		rescue StandardError => e
			# If parsing fails, log error and return false (assume no update needed)
			puts "Error comparing versions '#{new_version}' and '#{current_version}': #{e.message}"
			false
		end
	end

	# Parse version string into numbers and pre-release identifier
	def parse_version_parts(version_string)
		# Split on first non-digit, non-dot character
		if version_string =~ /^(\d+(?:\.\d+)*)(.*)$/
			numbers_part = $1
			prerelease_part = $2.strip
			
			numbers = numbers_part.split('.').map(&:to_i)
			prerelease = prerelease_part.empty? ? nil : prerelease_part.downcase.gsub(/^[.-]/, '')
			
			{ numbers: numbers, prerelease: prerelease }
		else
			# Fallback for malformed versions
			{ numbers: [0], prerelease: version_string.downcase }
		end
	end

	# Compare two arrays of version numbers
	def compare_version_numbers(new_nums, current_nums)
		# Pad shorter version array with zeros
		max_length = [new_nums.length, current_nums.length].max
		new_nums = new_nums.dup.fill(0, new_nums.length, max_length - new_nums.length)
		current_nums = current_nums.dup.fill(0, current_nums.length, max_length - current_nums.length)
		
		new_nums <=> current_nums
	end

	# Compare pre-release identifiers
	# nil (stable release) > any pre-release
	# Within pre-releases: rc > beta > alpha
	def compare_prerelease(new_pre, current_pre)
		return 0 if new_pre == current_pre
		
		# Stable release (nil) is always greater than pre-release
		return 1 if new_pre.nil? && !current_pre.nil?
		return -1 if !new_pre.nil? && current_pre.nil?
		
		# Both are pre-releases, compare them
		pre_order = { 'alpha' => 1, 'beta' => 2, 'rc' => 3 }
		
		new_order = pre_order[new_pre] || 0
		current_order = pre_order[current_pre] || 0
		
		new_order <=> current_order
	end
end