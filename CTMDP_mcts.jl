using MCTS
using pattern

include("CTMDP.jl")

mctsRng = MersenneTwister(1)




function rollOutPolicy(s::SType, rngState)
    return pattern.g_noaction::MCTS.Action #our roll-out policy is the silent policy
end


#TODO: Need to deal with the fact that this is a CTMDP,
#so only one needs to transition at a time!
#Since we are using Monte-Carlo, we might be able to use the history
#and actually handle non-exponential time distributions?
function findFirsti(Snow::SType, trantimes::typeof(pattern.teaTime), rngState::AbstractRNG)
    #Find which state will transition
    N = length(Snow)

    tmin = Inf
    ifirst = 1
    for i in 1:N
       t = -trantimes[Snow[i]] * log(1-rand(rngState))
       if t < tmin
         ifirst = i
         tmin = t
       end
    end
    
    return ifirst
end



function getNextState!(Snew::SType, Snow::SType, a::typeof(pattern.g_noaction), rngState::AbstractRNG)
    #copy!(Snew, Snow)
    
    #Only transition the one with the earliest event in the race!
    ifirst = findFirsti(Snow, pattern.teaTime, rngState)
    #Snew[ifirst] = randomChoice(Snow[ifirst], a[1] == ifirst, a[2], rngState)
    
    for i in 1:length(Snew)
        if i == ifirst
            Snew[ifirst] = randomChoice(Snow[ifirst], a[1] == ifirst, a[2], rngState)
        else
            Snew[i] = Snow[i] 
        end
    end
#     
    return nothing
end

function getReward!(R::Float32, S::SType, a::typeof(pattern.g_noaction), pars)    
    #assert(pars.β < 0.9f0) #We make the assumption that action cost is small relative to collision cost
    
    R = Reward(S, a, pars.β::Float32)
    
    terminate = false;
    #This is a terminal state...
    if( R <=  collisionCost)
        terminate = true
    end
    return terminate
end

Afun = pattern.validActions


assert (typeof(pattern.g_noaction) == MCTS.Action)
assert (SType == MCTS.State)




function genMCTSdict(d, ec, n, β)
    pars = MCTS.SPWParams{MCTS.Action}(true, d,ec,n,β, Afun,rollOutPolicy,getNextState!,getReward!, S2LIDX, mctsRng)
    mcts = MCTS.SPW{MCTS.Action}(pars)
    return mcts
end

d = int16(50)           
ec = abs(collisionCost)
n = int32(1000)
β = 0.0f0
mcts = genMCTSdict(d, ec, n, β)

mctsPolicy = S -> MCTS.selectAction!(mcts, S)

# let S = [:LD2, :RB1, :R, :U1]
# 
# @time for lo in 1:10 MCTS.selectAction!(mcts, S) end
# 
# end



# 
# gridworld = GenerativeModel(getInitialState,getNextState,getReward)
# 
# simulate(gridworld,mcts,policy,nSteps,rng)