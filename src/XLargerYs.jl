
module XLargerYs

	export XLargerY
	import Base: length

	struct XLargerY{T <: Real}
		x::Vector{T}
		y::Vector{T}
		upper::Vector{Int64} # Upper index in y so that x > y holds
		N::Int64 # Number of combinations of x and y

		# Basic constructor
		function XLargerY(x::AbstractVector{T}, y::AbstractVector{T}, upper::AbstractVector{<: Integer}) where T <: Real
			@assert all(u -> u > 0, upper)
			@assert length(x) == length(upper)
			@assert length(y) >= maximum(upper)
			return new{T}(x, y, upper, sum(upper))
		end

		# Constructor if Δ has to be determined
		function XLargerY(x::AbstractVector{T}, y::AbstractVector{T}) where T <: Real
			# Check if sorted
			if any(diff(x) .<= 0) || any(diff(y) .<= 0)
				error("x and y must be sorted and cannot contain duplicates")
			end
			# Only use combinations where x > y
			upper = Vector{Int64}(undef, length(x))
			local i
			local j = 1
			@inbounds for outer i = 1:length(x)
				found = false
				for outer j = j:length(y)
					if x[i] ≤ y[j]
						found = true
						break
					end
				end
				if found
					j == 1 && error("Smallest x is less than or equal to smallest y")
					i == length(x) && error("Largest y is equal to or larger than largest x")
				else # Not found an upper
					break
				end
				upper[i] = j-1
			end
			# Fill remaining elements up with maximum possible Δ
			upper[i:end] .= length(y)
			return new{T}(x, y, upper, sum(upper))
		end
	end 



	"""
		 XLargerYs.iterate(xly, outer_loop, inner_loop)

		 Two loops, one for x (outer) and one for y (inner).
		 For your purposes, use a vector with the length of XLargerY.N.
		 In each iteration of x, the respective elements in that array are in i:j (y varies over these).

		 outer_loop: iterate through x.
		 Do everything independent of y here.
		 To get the respective x use `xly.x[n]`.
		
		 inner_loop: y varies
		 To get the respective y use `xly.y[m]`.
		 Additionally, index `l` is provided according to `l = i:j`.

		 No @inbounds is used.
	"""
	macro iterate(xly, outer_loop, inner_loop)
		esc(quote
			local i = 1
			local j = 0
			for (n, u) = enumerate($xly.upper)
				j += u
				$outer_loop
				for (m, l) = enumerate(i:j)
					$inner_loop
				end
				i += u
			end
		end)
	end

	function convert(::Type{XLargerY{<: T}}, b::XLargerY) where T
		XLargerY(convert(T, b.x), convert(T, b.y), b.upper)
	end

	length(xly::XLargerY) = xly.N

	function combinations(xly::XLargerY{T})::Vector{NTuple{2, T}} where T <: Real
		q = Vector{NTuple{2, T}}(undef, xly.N)
		@iterate(
			xly,
			# Do nothing in the outer loop
			nothing,
			# Store x and y in the inner loop
			q[l] = (xly.x[n], xly.y[m])
		)
		return q
	end

end

