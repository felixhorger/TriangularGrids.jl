
module TriangularGrids

	export TriangularGrid
	import Base: length

	struct TriangularGrid{T <: Real}
		q1::Vector{T} # q for quantity
		q2::Vector{T}
		Δ::Vector{Int64} # How many steps to make in q1 before q2 needs to be increased
		N::Int64 # Number of combinations of q1 and q2

		# Basic constructor
		function TriangularGrid(q1::AbstractVector{T}, q2::AbstractVector{T}, Δ::AbstractVector{<: Integer}) where T <: Real
			@assert all(Δ .> 0)
			@assert length(q1) >= maximum(Δ)
			@assert length(q2) == length(Δ)
			return new{T}(q1, q2, Δ, sum(Δ))
		end

		# Constructor if Δ has to be determined
		function TriangularGrid(q1::AbstractVector{T}, q2::AbstractVector{T}) where T <: Real
			# Check if sorted
			if any(diff(q1) .<= 0) || any(diff(q2) .<= 0)
				error("q1 and q2 must be sorted and cannot contain duplicates")
			end
			# Only use combinations where q2 > q1
			Δ = Vector{Int64}(undef, length(q2))
			local i
			local j = 1
			@inbounds for outer i = 1:length(q2)
				for outer j = j:length(q1)
					q1[j] > q2[i] && break
				end
				if q1[j] > q2[i]
					j -= 1
				else
					break
				end
				Δ[i] = j
			end
			# Fill remaining elements up with maximum possible Δ
			Δ[i:end] .= length(q1)
			return new{T}(q1, q2, Δ, sum(Δ))
		end
	end 



	"""
		 TriangularGrids.iterate(grid, loop2, loop1)

		 Two loops, one for q2 (outer) and one for q1 (inner).
		 For your purposes, use a vector with the length of TriangularGrid.N.
		 In each iteration of q2, the respective elements in that array are in i:j (q1 varies over these).

		 Assume the grid is names `grid`.
		
		 loop2: iterate through q2.
		 Do everything independent of q1 here.
		 To get the respective q2 use `grid.q2[n]`.
		
		 loop1: q1 varies
		 To get the respective q1 use `grid.q1[m]`.
		 Additionally, index `l` is provided according to `l = i:j`.

		 No @inbounds is used.
	"""
	macro iterate(grid, loop2, loop1)
		esc(quote
			local i = 1
			for (n, δ) = enumerate($grid.Δ)
				j = i + δ - 1
				$loop2
				for (m, l) = enumerate(i:j)
					$loop1
				end
				i += δ
			end
		end)
	end

	function convert(::Type{TriangularGrid{<: T}}, b::TriangularGrid) where T
		TriangularGrid(convert(T, b.q1), convert(T, b.q2), b.Δ)
	end

	@inline function length(grid::TriangularGrid)
		grid.N
	end

	function combinations(grid::TriangularGrid{T})::Vector{NTuple{2, T}} where T <: Real
		q = Vector{NTuple{2, T}}(undef, grid.N)
		@iterate(
			grid,
			# Do nothing in the outer loop
			nothing,
			# Store q1 and q2 in the inner loop
			q[l] = (grid.q1[m], grid.q2[n])
		)
		return q
	end

end

