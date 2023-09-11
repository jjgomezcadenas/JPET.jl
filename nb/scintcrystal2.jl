### A Pluto.jl notebook ###
# v0.19.27

using Markdown
using InteractiveUtils

# ╔═╡ 24e81d50-081b-41a0-bc90-1bb7ec62e964
using Geant4

# ╔═╡ 87e73606-5087-11ee-1d43-6dcac9b7e642
function findrdir()
	nbdir = split(@__DIR__,"/")
	reduce(string, [string(x,"/") for x in nbdir[1:end-1]])
end

# ╔═╡ f6fe4446-c826-4a67-ae19-9500b9b790e2
using Pkg; Pkg.activate(findrdir())

# ╔═╡ Cell order:
# ╠═f6fe4446-c826-4a67-ae19-9500b9b790e2
# ╠═87e73606-5087-11ee-1d43-6dcac9b7e642
# ╠═24e81d50-081b-41a0-bc90-1bb7ec62e964
