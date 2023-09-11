using Geant4
	using Geant4.SystemOfUnits
	using Geant4.SystemOfUnits: cm3
	using CairoMakie
	using GeometryBasics, Rotations, IGLWrap_jll


function findrdir()
	nbdir = split(@__DIR__,"/")
	reduce(string, [string(x,"/") for x in nbdir[1:end-1]])
end



begin
	srcdir = string(findrdir(), "src")
	include(joinpath(srcdir, "crstDet.jl"))
	include(joinpath(srcdir, "crstSimData.jl"))
	include(joinpath(srcdir, "crstUserActions.jl"))
end

crstd = CrstDetector(checkOverlaps=true, crstXY=3.5*mm, 
                     crstZ=10.0*mm, crstName="LYSO")

particlegun = G4JLGunGenerator(particle = "gamma", 
                               energy = 511keV, 
                               direction = G4ThreeVector(0,0,1), 
                               position = G4ThreeVector(0,0,-crstd.crstZ/2))

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


world = GetWorldVolume()

# ╔═╡ 9790d919-510c-4aff-a497-c0a0a3b71c4a
begin
	fig2 = Figure(resolution=(500,500))
	s2 = LScene(fig2[1,1])
	Geant4.draw!(s2, world, wireframe=true)
end


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


nexttrigger(app)


function drawdetector!(s, app)
    world = GetWorldVolume()
    Geant4.draw!(s, world, wireframe=true)
    return s
end


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

begin
	fig = Figure(resolution=(500,500))
	s = LScene(fig[1,1])
	drawdetector!(s, app)
	drawevent!(s, app)
	display(fig)
end

