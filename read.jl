using JSONTables, DataFrames, Printf
using LazyJSON, ProgressMeter
using JLD2, FileIO
LARGE_INT = typemax(Int32) 

function read_json(filename::String, isdf::Bool=true)
    str = String(read(filename))
    if isdf
        json = jsontable(str)
        df = DataFrame(json)
        return df
    else
        return LazyJSON.value(str)
    end
end;

function get_competition_list(printlist::Bool=false)
    filename = "../../open-data/data/competitions.json"
    df = read_json(filename)
    if printlist print(df) end
    return df
end;

function get_matches_id(competition::String, season::String)
    competitions = get_competition_list()
    idx = map(&, competitions.season_name.==season, competitions.competition_name .== competition)
    competition_id = competitions[idx, :competition_id][1] 
    season_id      = competitions[idx, :season_id][1]
    filename = @sprintf "../../open-data/data/matches/%d/%d.json" competition_id season_id
    json = read_json(filename, false)
    match_id = []
    for i=1:length(json)
        push!(match_id, Int32(json[i]["match_id"])) 
    end
    return match_id
end;

function get_events(id)
    filename = @sprintf "../../open-data/data/events/%d.json" id
    json = read_json(filename, false)
    return json
end

function print_teams(competition::String, season::String)
    matches_id = get_matches_id(competition, season)
    for match_id in matches_id
        action_json = get_events(match_id)
        home_team = action_json[1]["team"]["name"]
        away_team = action_json[2]["team"]["name"]
        str = @sprintf "id=%10d \t home=%25s \t away=%25s" match_id home_team away_team 
        println(str)
    end
end

function get_gk_names(competition::String, season::String)
    matches_id = get_matches_id(competition, season)
    gk_names = []
    gk_ids   = []
    for match_id in matches_id
        action_json = get_events(match_id)
        lineup = action_json[1]["tactics"]["lineup"]
        for player in lineup
            if player["position"]["name"] == "Goalkeeper"
                id   = player["player"]["id"]
                name = player["player"]["name"]
                if name in gk_names
                else
                    push!(gk_names, name)
                    push!(gk_ids, id)
                end
            end
        end
    end
    return gk_names, gk_ids
end

function get_gk_passes_with_conseq(competition::String, season::String)
    matches_id = get_matches_id(competition, season)
    gk_names, gk_ids = get_gk_names(competition, season)
    matches_actions = []
    @showprogress "Reading..." 1 for match_id in matches_id
        possession = LARGE_INT
        gk_actions = []
        possession_lost_actions = []
        goal_kick_actions = []
        shot_actions = []
        action_json = get_events(match_id)
        for action_idx=1:length(action_json)
            # CHECK FOR GK ACTIONS
            action_name = action_json[action_idx]["type"]["name"]
            player_name = "No Player"
            try
                player_name = action_json[action_idx]["player"]["name"]
                iserror = false
            catch
                iserror = true
            end
            if player_name in gk_names
                push!(gk_actions, action_json[action_idx])
            end
            # CHECK FOR SHOT ACTIONS
            if action_name == "Shot"
                push!(shot_actions, action_json[action_idx])
            end
            # CHECK FOR PLOST ACTIONS
            if possession < Int32(action_json[action_idx]["possession"]) 
                push!(possession_lost_actions, action_json[action_idx])
            end
            # CHECK FOR GOAL KICK ACTIONS
            play_pattern = "No Pattern"
            if action_name == "Pass"
                try
                    play_pattern = action_json[action_idx]["play_pattern"]["name"]
                    iserror = false
                catch
                    iserror = true
                end
                if play_pattern == "From Goal Kick"
                    possession = Int32(action_json[action_idx]["possession"])
                    push!(goal_kick_actions, action_json[action_idx])
                end
            end
        end
        push!(matches_actions, [gk_actions, possession_lost_actions, goal_kick_actions, shot_actions])
    end
    return matches_actions
end


function get_gkick_len(competition::String, season::String)
    matches = get_gk_passes_with_conseq(competition, season);
    gkick_lengths     = []
    gkick_conseqs     = []
    gkick_conseqs_id  = []   
    @showprogress "Calculating..." 1 for match in matches
        gk_actions, plost_actions, goal_kick_actions, shot_actions = match
        for gkick in goal_kick_actions
            shot_id  = 0
            plost_id = 0
            gkick_conseq    = "None"
            gkick_conseq_id = 0
            gkick_id     = Int32(gkick["index"])
            gkick_length = Float32(gkick["pass"]["length"])
            for shot in shot_actions
                shot_id = Int32(shot["index"])
                if shot_id > gkick_id
                    gkick_conseq    = "Shot"
                    gkick_conseq_id = 1
                    break
                end
            end
            for plost in plost_actions
                plost_id = Int32(plost["index"])
                if plost_id > gkick_id
                    if plost_id < shot_id
                       gkick_conseq    = "PLost"
                       gkick_conseq_id = -1 
                       break               
                    end
                end
            end
            push!(gkick_lengths, gkick_length)
            push!(gkick_conseqs, gkick_conseq)
            push!(gkick_conseqs_id, gkick_conseq_id)
        end
    end
    season_filename = season[1:4] 
    save("../output/data-$competition-season-$season_filename.jld2", 
                            Dict("gkick_lengths" => gkick_lengths,
                                 "gkick_conseqs" => gkick_conseqs,
                                 "gkick_conseqs_id" => gkick_conseqs_id,
                                 ))
    return gkick_lengths, gkick_conseqs, gkick_conseqs_id  
end

function get_gkick_len_saved(competition::String, season::String)
    season_filename = season[1:4] 
    data = load("../output/data/data-$competition-season-$season_filename.jld2")
    return data["gkick_lengths"], data["gkick_conseqs"], data["gkick_conseqs_id"]
end