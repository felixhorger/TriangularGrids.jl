
module XLargerYs

	export XLargerY
	import Base: length

	struct XLargerY{T <: Real}
		x::Vector{T}
		y::Vector{T}
		Δ::Vector{Int64} # How many steps to make in x before y needs to be increased
		N::Int64 # Number of combinations of x and y

		# Basic constructor
		function XLargerY(x::AbstractVector{T}, y::AbstractVector{T}, Δ::AbstractVector{<: Integer}) where T <: Real
			@assert all(Δ .> 0)
			@assert length(x) >= maximum(Δ)
			@assert length(y) == length(Δ)
			return new{T}(x, y, Δ, sum(Δ))
		end

		# Constructor if Δ has to be determined
		function XLargerY(x::AbstractVector{T}, y::AbstractVector{T}) where T <: Real
			# Check if sorted
			if any(diff(x) .<= 0) || any(diff(y) .<= 0)
				error("x and y must be sorted and cannot contain duplicates")
			end
			# Only use combinations where y > x
			Δ = Vector{Int64}(undef, length(y))
			local i
			local j = 1
			@inbounds for outer i = 1:length(y)
				for outer j = j:length(x)
					x[j] > y[i] && break
				end
				if x[j] > y[i]
					j -= 1
				else
					break
				end
				Δ[i] = j
			end
			# Fill remaining elements up with maximum possible Δ
			Δ[i:end] .= length(x)
			return new{T}(x, y, Δ, sum(Δ))
		end
	end 



	"""
		 XLargerYs.iterate(xly, loop2, loop1)

		 Two loops, one for y (outer) and one for x (inner).
		 For your purposes, use a vector with the length of XLargerY.N.
		 In each iteration of y, the respective elements in that array are in i:j (x varies over these).

		 loop2: iterate through y.
		 Do everything independent of x here.
		 To get the respective y use `xly.y[n]`.
		
		 loop1: x varies
		 To get the respective x use `xly.x[m]`.
		 Additionally, index `l` is provided according to `l = i:j`.

		 No @inbounds is used.
	"""
	macro iterate(xly, loop2, loop1)
		esc(quote
			local i = 1
			for (n, δ) = enumerate($xly.Δ)
				j = i + δ - 1
				$loop2
				for (m, l) = enumerate(i:j)
					$loop1
				end
				i += δ
			end
		end)
	end

	function convert(::Type{XLargerY{<: T}}, b::XLargerY) where T
		XLargerY(convert(T, b.x), convert(T, b.y), b.Δ)
	end

	@inline function length(xly::XLargerY)
		xly.N
	end

	function combinations(xly::XLargerY{T})::Vector{NTuple{2, T}} where T <: Real
		q = Vector{NTuple{2, T}}(undef, xly.N)
		@iterate(
			xly,
			# Do nothing in the outer loop
			nothing,
			# Store x and y in the inner loop
			q[l] = (xly.x[m], xly.y[n])
		)
		return q
	end

end

