state("tropicJim")
{
    int room_id : 0x2E5A24;
}

startup
{
    vars.TimerModel = new TimerModel { CurrentState = timer };

    vars.splitTransitions = new Dictionary<int, int>(){
        {7, 11}, // Maintenance (Outer) -> Maintenance (Inner)
        {12, 6}, // Bunker -> Beach
        {8, 4}, // Jim's House (Outer) -> Jim's House (Entrance) 
        {21, 22}, // Elevator -> Basement
        {24, 25}, // Basement -> Splat
    };
}

init{
    vars.final_room = false;
}

start
{
    // Start on transition to opening dialogue
    return current.room_id == 2 && old.room_id == 3;
}

split
{
    // Split on defined transitions
    if (current.room_id != old.room_id){
        if (current.room_id == 26){
            vars.final_room = true;
        }
        if (((Dictionary<int, int>)vars.splitTransitions).ContainsKey(old.room_id)){
            return current.room_id == vars.splitTransitions[old.room_id];
        }
    }
    return false;
}

exit
{
    // End timer on game exit in final room
    if (vars.final_room){
        vars.TimerModel.Split();
    }
}