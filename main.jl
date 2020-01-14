using PyPlot
ioff()
using Turing
import MCMCChains
using StatsBase
include("./read.jl");

#---FUNCTIONS--FOR---DISTRIBUTIONS---
logistic(x, a, b) = 1.0 ./ (1.0 .+ exp.(b .* x .+ a))
    
function step_func(x, thresh, p1, p2)
        if x < thresh
            return p1
        else
            return p2
        end
end

function step3_func(x, thresh, thresh2, p1, p2, p3)
        if x < thresh
            return p1
        else
            if x < thresh2
                return p2
            else
                return p3
            end
        end
end
#-----------------------------------

function main()
    is3step = true
    competition = "La Liga"
    seasons = [
                #"2004/2005",
                #"2005/2006",
                #"2006/2007",
                #"2007/2008",
                #"2008/2009",
                #"2009/2010",
                #"2010/2011",
                "2011/2012",
                "2012/2013",
                "2013/2014",
                #"2014/2015",
                #"2015/2016",
                #"2016/2017",
                #"2017/2018",
                #"2018/2019",
            ]

    for idx_season=1:length(seasons)
        season = seasons[idx_season]
        println("Current season: $season")
        println("is 3 steps: $is3step")
        gkick_lengths, gkick_conseqs, gkick_conseqs_id = get_gkick_len_saved(competition, season)

        shots_dist  = []
        length_dist = []
        gkick_shots_length = []
        gkick_plost_length = []
        for idx=1:length(gkick_conseqs)
            if gkick_conseqs_id[idx] == 1
                push!(shots_dist, 1)
                push!(length_dist, gkick_lengths[idx]/100.0)
                push!(gkick_shots_length, gkick_lengths[idx])
            elseif gkick_conseqs_id[idx] == -1
                push!(shots_dist, 0)
                push!(length_dist, gkick_lengths[idx]/100.0)
                push!(gkick_plost_length, gkick_lengths[idx])
            end
        end

        n_data_points = 500
        if n_data_points < length(gkick_shots_length)
        else
            n_data_points = length(gkick_shots_length)
        end
        ind = sample(1:length(gkick_shots_length), n_data_points, replace=false)
        gkick_shots_length = gkick_shots_length[ind]
        gkick_plost_length = gkick_plost_length[ind]

        @model bernouli(s, l) = begin
            thresh ~ Uniform(0, 1)
            p1 ~ Uniform(0, 1)
            p2 ~ Uniform(0, 1)
            N = length(s)
            for i = 1:N
                p = step_func(l[i],thresh,p1,p2)
                s[i] ~ Bernoulli(p)
            end
        end;

        @model bernouli_3step(s, l) = begin
            thresh ~ Uniform(0, 1)
            thresh2 ~ Uniform(thresh, 1)
            p1 ~ Uniform(0, 1)
            p2 ~ Uniform(0, 1)
            p3 ~ Uniform(0, 1)
            N = length(s)
            for i = 1:N
                p = step3_func(l[i],thresh, thresh2, p1, p2, p3)
                s[i] ~ Bernoulli(p)
            end
        end;

        # Sample using NUTS.
        num_chains = 4
        iterations = 2300
        burnin = 300
        if is3step
            chain = mapreduce(
                c -> sample(bernouli_3step(shots_dist, length_dist), NUTS(200, 0.65), iterations, progress=true), 
                MCMCChains.chainscat, 
                1:num_chains);
        else
            chain = mapreduce(
                c -> sample(bernouli(shots_dist, length_dist), NUTS(200, 0.65), iterations, progress=true), 
                MCMCChains.chainscat, 
                1:num_chains);
        end
        #Burn-in
        chain = chain[burnin:end,:,:]
        # Test chains
        gel_test = gelmandiag(chain)

        mean_p1     = mean(chain[:p1].value)
        mean_p2     = mean(chain[:p2].value)
        mean_thresh = mean(chain[:thresh].value)
        step_name = ""
        if is3step
            mean_p3     = mean(chain[:p3].value)
            mean_thresh2 = mean(chain[:thresh2].value)
            step_name = "-3step"
        end

        figure()
        xlabel("Goal kick length [100 m]")
        ylabel("Probability of shot")
        title("Season $season")
        plot(length_dist, shots_dist, "ko")
        l = range(0,length=100,stop=1)
        if is3step
            plot([0, mean_thresh], [mean_p1, mean_p1], "ro-")
            plot([mean_thresh, mean_thresh2], [mean_p2, mean_p2], "go-")
            plot([mean_thresh2, 1], [mean_p3, mean_p3], "bo-")
        else
            plot([0, mean_thresh], [mean_p1, mean_p1], "ro-")
            plot([mean_thresh, 1], [mean_p2, mean_p2], "bo-")
        end
        # SAVE INFO
        season_filename = season[1:4] 

        savefig("../output/simulation$step_name-season-$season_filename.png")
        if is3step 
            save("../output/simulation$step_name-season-$season_filename.jld2", Dict("p1" => chain[:p1].value,
                                            "p2" => chain[:p2].value,
                                            "p3" => chain[:p3].value,
                                            "thresh" => chain[:thresh].value,
                                            "thresh2" => chain[:thresh2].value,
                                            "gel_test" => gel_test
                                            ))
        else 
            save("../output/simulation$step_name-season-$season_filename.jld2", Dict("p1" => chain[:p1].value,
                                            "p2" => chain[:p2].value,
                                            "thresh" => chain[:thresh].value,
                                            "gel_test" => gel_test
                                            ))
        end
        #---PLOTS---
        #hist(gkick_lengths, bins=40)
        #plot(gkick_lengths ,gkick_conseqs_id, "ko")
        #hist(gkicks_shots_length, color="r", bins=30, alpha=0.4);
        #hist(gkicks_plost_length, color="b", bins=Int32(floor(20*(length(gkicks_plost_length)/length(gkicks_shots_length)))), alpha=0.4);
    end
end

main()