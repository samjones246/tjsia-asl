state("tropicJim")
{
    int room_id : 0x2E5A24;
}

startup
{
    vars.Log = (Action<object>)((output) => print("[Process ASL] " + output));
    vars.TimerModel = new TimerModel { CurrentState = timer };

    // Map from room id to descriptive room name, for settings
    Dictionary <int, string> room_names = new Dictionary<int, string>() {
        { 1, "Overworld - Center" },
        { 2, "Intro Dialogue"},
        { 3, "Main Menu"},
        { 4, "Waking Up / Breaking in (Cutscene)"},
        { 5, "Overworld - House"},
        { 6, "Overworld - Beach"},
        { 7, "Overworld - Maintenance"},
        { 8, "Overworld - Jim's House"},
        { 9, "(Unused)"},
        { 10, "Jim enters Code (Cutscene)"},
        { 11, "Maintenance Shack"},
        { 12, "Bunker"},
        { 13, "Bunker - Computer"},
        { 14, "Jim's House - Entry"},
        { 15, "Jim's House - Office"},
        { 16, "Jim's House - Movie Room"},
        { 17, "Jim's House - Bedroom"},
        { 18, "Dr. Jim Tape - June 15th"},
        { 19, "Dr. Jim Tape - June 29th"},
        { 20, "Jim's House - Power Panel"},
        { 21, "Jim's House - Elevator"},
        { 22, "Elevator ride (Cutscene)"},
        { 23, "Jim's House - Basement dialogue"},
        { 24, "Jim's House - Basement"},
        { 25, "Basement Success/Fail (Cutscene)"},
        { 26, "Ending Dialogue"},
    };

    // Entries into 'embedded' rooms shouldn't count as exits from the containing room
    Dictionary<int, List<int>> no_exit = new Dictionary<int, List<int>>() {
        {12, new List<int>() {13}},
        {16, new List<int>() {18, 19}},
        {17, new List<int>() {20}},
    };

    vars.no_exit = (Function<int, int, bool>)((prev, new) => {
        return no_exit.ContainsKey(prev) && no_exit[prev].Contains(new);
    });

    // Default settings
    int[] defaults = new int[27];
    defaults[5] = 1; // Enter Overworld - House
    defaults[11] = 1; // Enter Maintenance Shack
    defaults[12] = 2; // Exit bunker
    defaults[14] = 1; // Enter Jim's House - Entry
    defaults[22] = 1; // Enter Elevetor Ride (Cutscene)
    defaults[25] = 1; // Enter Basement Success/Fail (Cutscene)

    settings.Add("enter", true, "Split on first enter");
    settings.Add("exit", true, "Split on first exit");
    for (int i = 1; i <= 26; i++)
    {
        settings.Add("enter_"+i, (defaults[i] & 1) > 0, room_names[i], "enter");
        settings.Add("exit_"+i, (defaults[i] & 2) > 0, room_names[i], "exit");
    }
}

init{
    vars.final_room = false;

    vars.has_entered = new bool[27];
    vars.has_exited = new bool[27];
}

start
{
    // Start on transition to opening dialogue
    return current.room_id == 2 && old.room_id == 3;
}

split
{
    // Split on enabled transitions
    if (current.room_id != old.room_id){
        if (current.room_id == 26){
            vars.final_room = true;
        }
        bool do_split = false;
        do_split  = settings["enter_"+current.room_id] && !vars.has_entered[current.room_id];
        do_split |= settings["exit_"+old.room_id]      && !vars.has_exited[old.room_id] 
                                                       && !vars.no_exit(old.room_id, current.room_id);
        vars.has_entered[current.room_id] = true;
        vars.has_exited[old.room_id] = true;
        return do_split;
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