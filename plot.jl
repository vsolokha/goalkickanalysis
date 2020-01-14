using PyPlot
using MCMCChains
using FileIO
using StatsBase
using Statistics
using DataFrames

include("./read.jl")
ioff()

function reg(x,y)
    x= floor.(Int32, x)
    data = DataFrame(X=x, Y=y)
    ols = lm(@formula(Y ~ X), data)
    b = coeftable(ols).cols[1][1]
    k = coeftable(ols).cols[1][2]
    tval_k = round.(coeftable(ols).cols[3][2], digits=2)
    return b, k, tval_k
end

function plot_pitch()
    pitch_dimensions = Dict(
        "length" => 104,
        "width"  => 68,
        "pbox_y_min" => 13.84,
        "pbox_y_max" => 54.16,
        "pbox_xright_min" => 87.5,
        "pbox_xright_max" => 104.0,
        "pbox_xleft_min"  => 0.0,
        "pbox_xleft_max"  => 16.5,
        "goal_y_min" => 30.34,
        "goal_y_max" => 37.16,
        "goal_xright_min" => 103.7,
        "goal_xright_max" => 104.0,
        "goal_xleft_min"  => 0.0,
        "goal_xleft_max"  => 0.3,
        "gbox_y_min" => 24.84,
        "gbox_y_max" => 43.16,
        "gbox_xright_min" => 99.5,
        "gbox_xright_max" => 104.0,
        "gbox_xleft_min"  => 0.0,
        "gbox_xleft_max"  => 4.5,
        "halfway_y_min"   => 0.0,
        "halfway_y_max"   => 68.0,
        "halfway_x"       => 52,
        "penalty_left_x"  => 11,
        "kickoff_x"       => 52,
        "penalty_right_x" => 93,
        "kickoff_y"       => 34,
        "circle_r"        => 9.15,
        "circle_cx_left"  => 10.5,
        "circle_cx_cent"  => 52,
        "circle_cx_right" => 93.5,
        "pitch_rect_cx_left"  => 0.0,
        "pitch_rect_cy"  => 20,
        "pitch_rect_cx_right" => 87.5,
        "pitch_rect_width_right"  => 16.5,
        "pitch_rect_width_left"   => 16, 
        "pitch_rect_height" => 30,
        "color" => "#F1F1F1",
    )

    f = figure()
    ax = gca()
    lines_x = []
    lines_y = []
    scatter_x = []
    scatter_y = []
    circle_centers = []
    circle_radius  = []
    rectangles = []

    push!(lines_x, [0,0,pitch_dimensions["length"],pitch_dimensions["length"],0])
    push!(lines_y,[0,pitch_dimensions["width"],pitch_dimensions["width"],0,0])
    push!(lines_x, [pitch_dimensions["pbox_xleft_min"],pitch_dimensions["pbox_xleft_max"],pitch_dimensions["pbox_xleft_max"], pitch_dimensions["pbox_xleft_min"]])
    push!(lines_y, [pitch_dimensions["pbox_y_min"],pitch_dimensions["pbox_y_min"],pitch_dimensions["pbox_y_max"], pitch_dimensions["pbox_y_max"]])
    push!(lines_x, [pitch_dimensions["pbox_xright_max"],pitch_dimensions["pbox_xright_min"],pitch_dimensions["pbox_xright_min"], pitch_dimensions["pbox_xright_max"]])
    push!(lines_y, [pitch_dimensions["pbox_y_min"],pitch_dimensions["pbox_y_min"],pitch_dimensions["pbox_y_max"], pitch_dimensions["pbox_y_max"]])
    push!(lines_x, [pitch_dimensions["goal_xleft_min"],pitch_dimensions["goal_xleft_max"],pitch_dimensions["goal_xleft_max"], pitch_dimensions["goal_xleft_min"]])
    push!(lines_y, [pitch_dimensions["goal_y_min"],pitch_dimensions["goal_y_min"],pitch_dimensions["goal_y_max"], pitch_dimensions["goal_y_max"]])
    push!(lines_x, [pitch_dimensions["goal_xright_max"],pitch_dimensions["goal_xright_min"],pitch_dimensions["goal_xright_min"], pitch_dimensions["goal_xright_max"]])
    push!(lines_y, [pitch_dimensions["goal_y_min"],pitch_dimensions["goal_y_min"],pitch_dimensions["goal_y_max"], pitch_dimensions["goal_y_max"]])
    push!(lines_x, [pitch_dimensions["gbox_xleft_min"],pitch_dimensions["gbox_xleft_max"],pitch_dimensions["gbox_xleft_max"], pitch_dimensions["gbox_xleft_min"]])
    push!(lines_y, [pitch_dimensions["gbox_y_min"],pitch_dimensions["gbox_y_min"],pitch_dimensions["gbox_y_max"], pitch_dimensions["gbox_y_max"]])
    push!(lines_x, [pitch_dimensions["gbox_xright_max"],pitch_dimensions["gbox_xright_min"],pitch_dimensions["gbox_xright_min"], pitch_dimensions["gbox_xright_max"]])
    push!(lines_y, [pitch_dimensions["gbox_y_min"],pitch_dimensions["gbox_y_min"],pitch_dimensions["gbox_y_max"], pitch_dimensions["gbox_y_max"]])
    push!(lines_x, [pitch_dimensions["halfway_x"],pitch_dimensions["halfway_x"]])
    push!(lines_y, [pitch_dimensions["halfway_y_min"],pitch_dimensions["halfway_y_max"]])
    for line_idx=1:length(lines_x)
        ax.plot(lines_x[line_idx], lines_y[line_idx], "k", zorder=5)
    end 
    push!(scatter_x, [pitch_dimensions["penalty_left_x"],])
    push!(scatter_x, [pitch_dimensions["penalty_right_x"],])
    push!(scatter_x, [pitch_dimensions["kickoff_x"],])
    push!(scatter_y, [pitch_dimensions["kickoff_y"],])
    push!(scatter_y, [pitch_dimensions["kickoff_y"],])
    push!(scatter_y, [pitch_dimensions["kickoff_y"],])
    for scatter_idx=1:length(scatter_x)
        ax.scatter(scatter_x[scatter_idx], scatter_y[scatter_idx], color="k", zorder=5)
    end 
    push!(rectangles, plt.Rectangle([pitch_dimensions["pitch_rect_cx_right"],pitch_dimensions["pitch_rect_cy"]], 
    pitch_dimensions["pitch_rect_width_right"], pitch_dimensions["pitch_rect_height"],
    ls="-",color=pitch_dimensions["color"], zorder=2,alpha=1))
    push!(rectangles, plt.Rectangle([pitch_dimensions["pitch_rect_cx_left"],pitch_dimensions["pitch_rect_cy"]], 
        pitch_dimensions["pitch_rect_width_left"], pitch_dimensions["pitch_rect_height"],
        ls="-",color=pitch_dimensions["color"], zorder=2,alpha=1))
    push!(rectangles, plt.Rectangle((0,0), pitch_dimensions["length"],pitch_dimensions["width"],color=pitch_dimensions["color"],zorder=1,alpha=1))
    for rect in rectangles
    ax.add_artist(rect)
    end           
    push!(circle_centers, [pitch_dimensions["circle_cx_left"], pitch_dimensions["kickoff_y"]])
    push!(circle_centers, [pitch_dimensions["circle_cx_cent"], pitch_dimensions["kickoff_y"]])
    push!(circle_centers, [pitch_dimensions["circle_cx_right"],pitch_dimensions["kickoff_y"]])
    for circle_idx=1:length(circle_centers)
        circ = plt.Circle(circle_centers[circle_idx], pitch_dimensions["circle_r"], ls="solid", color="k", fill=false, zorder=1)
        ax.add_artist(circ)
    end             
    ax.set_aspect("equal")
    ax.axis("off")
    return ax, pitch_dimensions
end

function get_from_chain(name, chain)
    return collect(Iterators.flatten(chain[name][:,:,:]))
end

function plot_threshs(is3step::Bool = false)
    seasons = [
        "2004/2005",
        "2005/2006",
        "2006/2007",
        "2007/2008",
        "2008/2009",
        "2009/2010",
        "2010/2011",
        "2011/2012",
        "2012/2013",
        "2013/2014",
        "2014/2015",
        "2015/2016",
        "2016/2017",
        "2017/2018",
        "2018/2019",
    ]
    season_int = []
    p1_med = []; p1_low = []; p1_high = []  
    p2_med = []; p2_low = []; p2_high = []  
    t1_med = []; t1_low = []; t1_high = []  
    if is3step
        p3_med = []; p3_low = []; p3_high = []  
        t2_med = []; t2_low = []; t2_high = []  
    end

    step_name = ""
    folder_name = "2-step"
    if is3step
        folder_name = "3-step"
        step_name = "-3step"
    end

    for season in seasons
        season_filename = season[1:4] 
        push!(season_int, parse(UInt16, season_filename))
        data = load("../output/$folder_name/simulation$step_name-season-$season_filename.jld2")
        p1 = get_from_chain("p1", data)
        p2 = get_from_chain("p2", data)
        t1 = get_from_chain("thresh", data)
        push!(p1_med,  median(p1)) 
        push!(p1_low,  quantile(p1, 0.25)) 
        push!(p1_high, quantile(p1, 0.75))
        push!(p2_med,  median(p2)) 
        push!(p2_low,  quantile(p2, 0.25)) 
        push!(p2_high, quantile(p2, 0.75))
        push!(t1_med,  median(t1)) 
        push!(t1_low,  quantile(t1, 0.25)) 
        push!(t1_high, quantile(t1, 0.75))
        if is3step
            p3 = get_from_chain("p3", data)
            t2 = get_from_chain("thresh2", data)
            push!(p3_med,  median(p3)) 
            push!(p3_low,  quantile(p3, 0.25)) 
            push!(p3_high, quantile(p3, 0.75))
            push!(t2_med,  median(t2)) 
            push!(t2_low,  quantile(t2, 0.25)) 
            push!(t2_high, quantile(t2, 0.75))
        end
        
    end

    if is3step
        t1_err = (t1_high.-t1_low)./2.0
        t2_err = (t2_high.-t2_low)./2.0
        p1_err = (p1_high.-p1_low)./2.0
        p2_err = (p2_high.-p2_low)./2.0
        p3_err = (p3_high.-p3_low)./2.0
        f, ax = subplots(figsize=(9, 7), nrows=2, ncols=1, sharex=true)
        ax[1].grid(true)
        ax[2].grid(false)
        ax[1].set_ylim(0,150)
        ax[2].set_ylim(0,0.25)
        ax[1].errorbar(x=season_int, y=t1_med.*1e2, yerr=t1_err.*1e2, capsize=4, fmt="o", color="b", markersize = 4, lw=0.5, label = "short to medium")
        ax[1].errorbar(x=season_int, y=t2_med.*1e2, yerr=t2_err.*1e2, capsize=4, fmt="o", color="g", markersize = 4, lw=0.5, label = "medium to long")
        ax[2].bar(season_int.-0.2, p1_med, capsize=3, yerr=p1_err, width=0.2, color="r", ecolor="r", label = "short")
        ax[2].bar(season_int.+0.0, p2_med, capsize=3, yerr=p2_err, width=0.2, color="b", ecolor="b", label = "medium")
        ax[2].bar(season_int.+0.2, p3_med, capsize=3, yerr=p3_err, width=0.2, color="g", ecolor="g", label = "long")
        locs, labels = xticks()
        xticks(rotation=45)
        ax[1].set_ylabel("pass length [m]")
        ax[2].set_ylabel("probability")
        ax[2].set_xlabel("season")
        #Regression
        b,k,tval_k = reg(season_int, t1_med.*1e2)
        ax[1].plot(season_int, k .* season_int .+ b,  "b--", lw=1, label = "slope T-value = $tval_k")
        b,k,tval_k = reg(season_int, t2_med.*1e2)
        ax[1].plot(season_int, k .* season_int .+ b,  "g--", lw=1, label = "slope T-value = $tval_k")
        ax[1].legend()
        ax[2].legend()
    else
        t1_err = (t1_high.-t1_low)./2.0
        p1_err = (p1_high.-p1_low)./2.0
        p2_err = (p2_high.-p2_low)./2.0
        f, ax = subplots(figsize=(9, 7),nrows=2, ncols=1, sharex=true)
        ax[1].grid(true)
        ax[2].grid(false)
        ax[1].set_ylim(0,150)
        ax[2].set_ylim(0,0.25)
        ax[1].errorbar(x=season_int, y=t1_med.*1e2, yerr=t1_err.*1e2, capsize=4, fmt="o", color="b", markersize = 4, lw=0.5, label = "short to long")
        ax[2].bar(season_int.-0.1, p1_med, capsize=3, yerr=p1_err, width=0.2, color="r", ecolor="r", label = "short")
        ax[2].bar(season_int.+0.1, p2_med, capsize=3, yerr=p2_err, width=0.2, color="b", ecolor="b", label = "long")
        locs, labels = xticks()
        xticks(rotation=45)
        ax[1].set_ylabel("pass length [m]")
        ax[2].set_ylabel("probability")
        ax[2].set_xlabel("season")
        #Regression
        b,k,tval_k = reg(season_int, t1_med.*1e2)
        ax[1].plot(season_int, k .* season_int .+ b,  "b--", lw=1, label = "slope T-value = $tval_k")
        ax[1].legend()
        ax[2].legend()
        
    end
    tight_layout()
    savefig("../output/errplot$step_name-season.png")

    if is3step
        t1_avg = mean(t1_med.*1e2)
        t2_avg = mean(t2_med.*1e2)
        p1_avg = mean(p1_med.*1e2)
        p2_avg = mean(p2_med.*1e2)
        p3_avg = mean(p3_med.*1e2)    
        zones = []
        ax, pitch_dim = plot_pitch()
        ax.set_title("Goal Kick Zones")
        push!(zones, [plt.Rectangle((0,0), t1_avg, pitch_dim["width"],ls="-",color="r",alpha=0.5, zorder=6), floor(Int16, p1_avg)])
        push!(zones, [plt.Rectangle((t1_avg,0), t2_avg-t1_avg, pitch_dim["width"],ls="-",color="b",alpha=0.5, zorder=6), floor(Int16, p2_avg)])
        push!(zones, [plt.Rectangle((t2_avg,0), pitch_dim["length"]-t2_avg, pitch_dim["width"],ls="-",color="g",alpha=0.5, zorder=6), floor(Int16, p3_avg)])
        for zone in zones
            p = zone[2]
            ax.add_artist(zone[1])
            rx, ry = zone[1].get_xy()
            cx = rx + zone[1].get_width()/2.0
            cy = ry + zone[1].get_height()/2.0
            ax.annotate("$p%", (cx, cy), color="w", weight="bold", fontsize=16, ha="center", va="center", zorder=7)
        end
        savefig("../output/pitch$step_name-season.png")      
    end
end

function plot_historical_data(competition, seasons) 
    lengths, a, b   = get_gkick_len_saved(competition, seasons[1])
    lengths_1, a, b = get_gkick_len_saved(competition, seasons[2])
    figure(figsize=(8,6));
    plt.grid(); 
    hist(lengths, bins=30, color="b", alpha=0.9, histtype="step", density=true, label=seasons[1]); 
    hist(lengths_1, bins=30, color="r", alpha=0.9, histtype="step", density=true, label=seasons[2])
    plt.title("$competition Goal Kicks"); 
    plt.ylabel("probability density [1/m]"); 
    plt.xlabel("length [m]"); 
    plt.legend();
end


