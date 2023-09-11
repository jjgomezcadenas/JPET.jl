### A Pluto.jl notebook ###
# v0.19.27

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 51cbc7dc-4fd6-11ee-21a0-79dff3925551
begin
	using Geant4
	using Geant4.SystemOfUnits
	using Geant4.SystemOfUnits: cm3
	using CairoMakie
	using GeometryBasics, Rotations, IGLWrap_jll
end

# ╔═╡ f87fd848-65a4-4f98-abb0-61be506d446c
using PlutoUI

# ╔═╡ b227f8e5-7641-4ef6-a112-a8fe7dfc2665
function findrdir()
	nbdir = split(@__DIR__,"/")
	reduce(string, [string(x,"/") for x in nbdir[1:end-1]])
end

# ╔═╡ 5d7dec74-f780-4a21-93bc-72c15321c94f
using Pkg; Pkg.activate(findrdir())

# ╔═╡ a23ad866-c90e-411c-8b7c-b0901f99540b
begin
	srcdir = string(findrdir(), "src")
	include(joinpath(srcdir, "crstDet.jl"))
	include(joinpath(srcdir, "crstSimData.jl"))
	include(joinpath(srcdir, "crstUserActions.jl"))
end

# ╔═╡ bdb405c8-08ac-40b2-bdc6-c9ad8a26c9e4
materials=["LYSO", "BGO", "CsI"]

# ╔═╡ 2e13c603-35c0-4729-bb3c-e17e228c2860
md""" Select crystal material : $(@bind matname Select(materials))"""

# ╔═╡ 3e413456-8d1f-402e-a4ed-d31ca2f5b0f6
md""" Select crystal size : $(@bind xy NumberField(1.0:0.1:10.0; default=3.5))"""

# ╔═╡ 5a749bfe-46e8-4789-999e-e381663ad731
md""" Select thickness size : $(@bind zz NumberField(5.0:0.1:20.0; default=10.0))"""

# ╔═╡ 16f11426-248d-4ae4-8e2a-0133fa07a783
crstd = CrstDetector(checkOverlaps=true, crstXY=xy*mm, crstZ=zz*mm, crstName=matname)

# ╔═╡ d89a1813-edf9-4b3f-b8c1-9674a0cce909
particlegun = G4JLGunGenerator(particle = "gamma", 
                               energy = 511keV, 
                               direction = G4ThreeVector(0,0,1), 
                               position = G4ThreeVector(0,0,-crstd.crstZ/2))

# ╔═╡ fd2b8a96-c714-406b-89c4-bc740e9262cb
app = G4JLApplication(; detector = crstd,             # detector with parameters
                        simdata = CrstSimData(),      # simulation data structure
                        generator = particlegun,      # primary particle generator
                        nthreads = 0,                 # # of threads (0 = no MT)
                        physics_type = QBBC,          # what physics list 
                        stepaction_method = stepaction!,           
                        begineventaction_method = beginevent!,    
                        pretrackaction_method = pretrackaction!,       
                        posttrackaction_method = posttrackaction!,     
                        beginrunaction_method = beginrun!              
                      );

# ╔═╡ 059d494b-a57c-4d0a-a85c-044880f1bd78
configure(app)

# ╔═╡ a1039211-5531-499b-b231-13bd38dbd9d3
initialize(app)

# ╔═╡ f5199691-7abb-4876-9e25-966c590abf68
#=╠═╡
begin
	fig = Figure(resolution=(500,500))
	s = LScene(fig[1,1])
	drawdetector!(s, app)
	drawevent!(s, app)
	display(fig)
end
  ╠═╡ =#

# ╔═╡ 54683e82-0f48-4304-b99c-7c30589b86d4
world = GetWorldVolume()

# ╔═╡ 9790d919-510c-4aff-a497-c0a0a3b71c4a
begin
	fig2 = Figure(resolution=(500,500))
	s2 = LScene(fig2[1,1])
	Geant4.draw!(s2, world, wireframe=true)
end

# ╔═╡ be74a146-36d9-4f99-bebb-fbd190672c6e
md"""
## Functions
"""

# ╔═╡ 600f20c3-91c6-4c8c-b2b1-d5a20ca79242
function nexttrigger(app)
    data = app.simdata[1]
    beamOn(app,1)
    n = 1
    while data.trigger
        beamOn(app,1)
        n += 1
    end
    println("Got a trigger after $n generated particles")
end

# ╔═╡ 9fedd49f-9365-44c9-b95b-de953d25c0f5
nexttrigger(app)

# ╔═╡ a32d845e-5561-40ac-8c70-d6ba5daddf54
function drawdetector!(s, app)
    world = GetWorldVolume()
    Geant4.draw!(s, world, wireframe=true)
    return s
end

# ╔═╡ ca197733-b532-4fa8-acb2-d93eea9937d2
function drawevent!(s, app, verbose=2)
    data = app.simdata[1]
    if verbose > 0
        println("Run info: Particle =", data.fParticle, 
                " Ekin = ", data.fEkin,
                " Edep = ", data.fEdep)
    end
    for t in data.tracks
        if t.particle == "gamma"
            if verbose > 1
                println(" gamma: energy = ", t.energy, " trkid =", t.trkid, 
					    " edep =", t.edep, 
                        " nof points = ", length(t.points), " points: = ", t.points)
                scatter!(s, t.points, markersize=7, color=:blue)
            end
        elseif t.particle == "e-"
            if verbose > 1
                println(" e-: energy = ", t.energy, " trkid =", t.trkid, 
					    " edep =", t.edep,
                        " nof points = ", length(t.points), " points: = ", t.points)
            end
            scatter!(s, t.points, markersize=7, color=:red)
        end
        
    end
end

# ╔═╡ 91fb546b-60b4-414e-a8c6-14a54e55986b
begin
	fig = Figure(resolution=(500,500))
	s = LScene(fig[1,1])
	drawdetector!(s, app)
	drawevent!(s, app)
	display(fig)
end

# ╔═╡ Cell order:
# ╠═5d7dec74-f780-4a21-93bc-72c15321c94f
# ╠═51cbc7dc-4fd6-11ee-21a0-79dff3925551
# ╠═f87fd848-65a4-4f98-abb0-61be506d446c
# ╠═b227f8e5-7641-4ef6-a112-a8fe7dfc2665
# ╠═a23ad866-c90e-411c-8b7c-b0901f99540b
# ╠═bdb405c8-08ac-40b2-bdc6-c9ad8a26c9e4
# ╠═2e13c603-35c0-4729-bb3c-e17e228c2860
# ╠═3e413456-8d1f-402e-a4ed-d31ca2f5b0f6
# ╠═5a749bfe-46e8-4789-999e-e381663ad731
# ╠═16f11426-248d-4ae4-8e2a-0133fa07a783
# ╠═d89a1813-edf9-4b3f-b8c1-9674a0cce909
# ╠═fd2b8a96-c714-406b-89c4-bc740e9262cb
# ╠═059d494b-a57c-4d0a-a85c-044880f1bd78
# ╠═a1039211-5531-499b-b231-13bd38dbd9d3
# ╠═9fedd49f-9365-44c9-b95b-de953d25c0f5
# ╠═91fb546b-60b4-414e-a8c6-14a54e55986b
# ╠═f5199691-7abb-4876-9e25-966c590abf68
# ╠═54683e82-0f48-4304-b99c-7c30589b86d4
# ╠═9790d919-510c-4aff-a497-c0a0a3b71c4a
# ╠═be74a146-36d9-4f99-bebb-fbd190672c6e
# ╠═600f20c3-91c6-4c8c-b2b1-d5a20ca79242
# ╠═a32d845e-5561-40ac-8c70-d6ba5daddf54
# ╠═ca197733-b532-4fa8-acb2-d93eea9937d2
