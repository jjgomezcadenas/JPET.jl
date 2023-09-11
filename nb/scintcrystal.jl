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

# ╔═╡ f2c222cd-4d0d-4881-bacf-a0e801e4cf0e
begin
	crslyso = CrstDetector(checkOverlaps=true, crstXY=xy*mm, crstZ=zz*mm, 
		                   crstName="LYSO")
	crsbgo = CrstDetector(checkOverlaps=true, crstXY=xy*mm, crstZ=zz*mm, 
		                   crstName="BGO")
	crscsi = CrstDetector(checkOverlaps=true, crstXY=xy*mm, crstZ=2.0*zz*mm, 
		                   crstName="CSI")
end

# ╔═╡ d89a1813-edf9-4b3f-b8c1-9674a0cce909
particlegun = G4JLGunGenerator(particle = "gamma", 
                               energy = 511keV, 
                               direction = G4ThreeVector(0,0,1), 
                               position = G4ThreeVector(0,0,-crscsi.crstZ/2))

# ╔═╡ fd2b8a96-c714-406b-89c4-bc740e9262cb
app = G4JLApplication(; detector = crslyso,             # detector with parameters
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

# ╔═╡ 03c35431-6229-4a65-8a47-d2bc02c4ed31
md"""
### Reinitialize with the desired crystal 
"""

# ╔═╡ 1941ffcb-08b2-47da-bf57-1adccc0da3e5
reinitialize(app, crsbgo)

# ╔═╡ 8cef0f85-36f4-4472-ac27-1fb689f7a4fa
reinitialize(app, crscsi)

# ╔═╡ 7ed549be-70cd-4aa9-a074-20a5ada205f6
world = GetWorldVolume()

# ╔═╡ 8a1b6173-335d-4518-be8a-0b359d9ebf7d
Geant4.draw(world; wireframe=true)

# ╔═╡ be74a146-36d9-4f99-bebb-fbd190672c6e
md"""
## Functions
"""

# ╔═╡ 54683e82-0f48-4304-b99c-7c30589b86d4
function plot_edep(edep1, edep2, edep3)
	f = Figure(resolution=(500,500))
	hist(f[1,1],edep1, bins = 200, color = :red, strokewidth = 1, 
		 strokecolor = :black)
	hist(f[1,2],filter(x->x>0 && x < 0.510, edep1), bins = 20, color = :red, strokewidth = 1, strokecolor = :black)
	hist(f[2,1],edep2, bins = 200, color = :red, strokewidth = 1, 
		 strokecolor = :black)
	hist(f[2,2],filter(x->x>0 && x < 0.510, edep2), bins = 20, color = :red, strokewidth = 1, strokecolor = :black)
	hist(f[3,1],edep3, bins = 200, color = :red, strokewidth = 1, 
		 strokecolor = :black)
	hist(f[3,2],filter(x->x>0 && x < 0.510, edep3), bins = 20, color = :red, strokewidth = 1, strokecolor = :black)
	f
end

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

# ╔═╡ 8d301e92-b5e9-4952-b269-b0c339f719e8
function run1(app; nrun=100)
    EDEP = zeros(nrun)
    nout = 0
    data = app.simdata[1]
    
    for i in 1:nrun
        beamOn(app,1)
        if data.trigger 
            nout+=1
        else
            data = app.simdata[1]
            EDEP[i] = data.fEdep
        end
    end
    EDEP
end

# ╔═╡ 9fedd49f-9365-44c9-b95b-de953d25c0f5
edeplyso = run1(app; nrun=50000);

# ╔═╡ ec2c3e0b-c820-4bc2-a992-6763b661cd7e
edepbgo = run1(app; nrun=50000);

# ╔═╡ dccc4dce-15c1-4765-898c-3a1d3ae227ab
edepcsi = run1(app; nrun=50000);

# ╔═╡ 1f5d2e10-5e54-4c98-9048-5f6d3d680cf9
plot_edep(edeplyso, edepbgo, edepcsi)

# ╔═╡ ca91330e-03b4-4173-88b9-77dd29042ad9
md"""
- Crystal = LYSO
- Dimensions: xy = $xy mm, z = $zz mm
- Fraction of events that interact in crystal = $(length(filter(x->x > 0, edeplyso)) /length(edeplyso))
- Fraction of events in photopeak = , $(length(filter(x->x > 0.509, edeplyso)) /length(edeplyso))

- Crystal = BGO
- Dimensions: xy = $xy mm, z = $zz mm
- Fraction of events that interact in crystal = $(length(filter(x->x > 0, edepbgo)) /length(edepbgo))
- Fraction of events in photopeak = , $(length(filter(x->x > 0.509, edepbgo)) /length(edepbgo))

- Crystal = CsI
- Dimensions: xy = $xy mm, z = $(2 *zz) mm
- Fraction of events that interact in crystal = $(length(filter(x->x > 0, edepcsi)) /length(edepcsi))
- Fraction of events in photopeak = , $(length(filter(x->x > 0.509, edepcsi)) /length(edepcsi))
"""

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

# ╔═╡ 03c70f12-a3f7-46da-a1d3-429d669fec09
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
# ╠═f2c222cd-4d0d-4881-bacf-a0e801e4cf0e
# ╠═d89a1813-edf9-4b3f-b8c1-9674a0cce909
# ╠═fd2b8a96-c714-406b-89c4-bc740e9262cb
# ╠═059d494b-a57c-4d0a-a85c-044880f1bd78
# ╠═a1039211-5531-499b-b231-13bd38dbd9d3
# ╠═03c35431-6229-4a65-8a47-d2bc02c4ed31
# ╠═9fedd49f-9365-44c9-b95b-de953d25c0f5
# ╠═1941ffcb-08b2-47da-bf57-1adccc0da3e5
# ╠═ec2c3e0b-c820-4bc2-a992-6763b661cd7e
# ╠═8cef0f85-36f4-4472-ac27-1fb689f7a4fa
# ╠═dccc4dce-15c1-4765-898c-3a1d3ae227ab
# ╠═1f5d2e10-5e54-4c98-9048-5f6d3d680cf9
# ╠═ca91330e-03b4-4173-88b9-77dd29042ad9
# ╠═03c70f12-a3f7-46da-a1d3-429d669fec09
# ╠═7ed549be-70cd-4aa9-a074-20a5ada205f6
# ╠═8a1b6173-335d-4518-be8a-0b359d9ebf7d
# ╠═be74a146-36d9-4f99-bebb-fbd190672c6e
# ╠═54683e82-0f48-4304-b99c-7c30589b86d4
# ╠═600f20c3-91c6-4c8c-b2b1-d5a20ca79242
# ╠═8d301e92-b5e9-4952-b269-b0c339f719e8
# ╠═a32d845e-5561-40ac-8c70-d6ba5daddf54
# ╠═ca197733-b532-4fa8-acb2-d93eea9937d2
