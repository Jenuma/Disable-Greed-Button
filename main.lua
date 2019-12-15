------------------------------------------------------------------------------\
-- Disable Greed Button                                                       |
------------------------------------------------------------------------------|
-- Binding of Isaac: Rebirth / Afterbirth+ Mod                                |
-- Jenuma, 10 December 2019                                                   |
-- Jenuma@live.com                                                            |
------------------------------------------------------------------------------|
-- This mod disables and disarms the button in Greed mode that begins the     |
-- waves of enemies until the room is clear, effectively removing the ability |
-- to suspend the waves.                                                      |
--                                                                            |
-- I created this mod because I was tired of accidentally pressing the button |
-- while trying to dodge enemy projectiles, or even worse, when I began a     |
-- wave and didn't get off the button in time.                                |
------------------------------------------------------------------------------/
local mod = RegisterMod("Disabled Greed Button", 1)

------------------------------------------------------------------------------\
-- Update()                                                                   |
------------------------------------------------------------------------------|
-- Iterates over all the GridEntities in the room until it finds the Greed    |
-- button, then disables it; should be called every tick while in the default |
-- room in Greed and Greedier modes.                                          |
------------------------------------------------------------------------------/
function mod:Update()
    local level = Game():GetLevel()
    local room = level:GetCurrentRoom()

    for i = 1, room:GetGridSize() do
        local grid_entity = room:GetGridEntity(i)
        if grid_entity ~= nil then
            -- To the best of my knowledge, no other pressure plate besides the
            -- Greed button can spawn in the default room.
            if grid_entity:GetType() == GridEntityType.GRID_PRESSURE_PLATE then
                mod:UpdateButtonState(grid_entity:ToPressurePlate())

                -- Don't waste processing power checking other entities.
                return
            end
        end
    end
end

------------------------------------------------------------------------------\
-- UpdateButtonState()                                                        |
------------------------------------------------------------------------------|
-- Updates the state of the given Greed button based on certain parameters    |
-- within the game's own state, such as whether the room is clear or what     |
-- wave the player is on.                                                     |
--                                                                            |
-- Documentation regarding pressure plate state is, as of writing this        |
-- script, embarassingly poor. Here's what I found to make the code more      |
-- digestable:                                                                |
--                                                                            |
-- GridEntityPressurePlate::State                                             |
-- 0 - The Greed button is pressable; initial state.                          |
-- 1 - The Greed button has been pressed, but can still be pressed (spiked).  |
-- 2 - The Greed button has been pressed twice and damage has been dealt.     |
-- 3 - The Greed button is transitioning to its next "form" (boss, nightmare).|
--                                                                            |
-- Basically, this function manually skips State 1 so the game believes the   |
-- spikey button has already been pressed, allowing us to run over it freely. |
-- (At least, that's what I believe. I don't know why it doesn't pause the    |
-- wave if that's the case, though, and I don't know if this makes the Lost   |
-- incur a reward penalty.)                                                   |
------------------------------------------------------------------------------/
function mod:UpdateButtonState(greed_button)
    local level = Game():GetLevel()
    local room = level:GetCurrentRoom()
    local last_wave
    local last_boss_wave

    -- Greedier difficulty has an extra non-boss wave, so I have to account
    -- for that.
    if Game().Difficulty == Difficulty.DIFFICULTY_GREED then
        last_wave = 8
    else
        last_wave = 9
    end
    last_boss_wave = last_wave + 2

    -- If the room is not clear, the button needs to be in State 2 so that we
    -- can freely run over it without taking damage or pausing the wave.
    if not room:IsClear() then
        greed_button.State = 2
        greed_button:Update()
    end

    -- If the room is clear and we haven't completed the nightmare wave yet,
    -- we want the button to be pressable.
    if room:IsClear() and
            level.GreedModeWave > 0 and
            level.GreedModeWave < last_boss_wave + 1 then
        greed_button.State = 0
        greed_button:Update()
    end

    -- If we have made it to the final wave, regardless what happens, the
    -- button needs to be allowed to transition into its final, inert state.
    if level.GreedModeWave == last_wave
            or level.GreedModeWave >= last_boss_wave then
        greed_button.State = 3
        greed_button:Update()
    end
end

------------------------------------------------------------------------------\
-- CheckRoom()                                                                |
------------------------------------------------------------------------------|
-- Checks to see if mode is Greed/Greedier, and if so checks if the current   |
-- room is a default room (the only type where Greed buttons should spawn).   |
-- If so, adds the Update() function to list of callbacks for MC_POST_UPDATE. |
-- Otherwise, it removes Update() from the list of callbacks to avoid wasting |
-- processing power.                                                          |
------------------------------------------------------------------------------/
function mod:CheckRoom()
    if Game().Difficulty == Difficulty.DIFFICULTY_GREED or
            Game().Difficulty == Difficulty.DIFFICULTY_GREEDIER then
                local level = Game():GetLevel()
                local room = level:GetCurrentRoom()

                if room:GetType() == RoomType.ROOM_DEFAULT then
                    mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.Update)
                    return
                end
    end

    mod:RemoveCallback(ModCallbacks.MC_POST_UPDATE, mod.Update)
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.CheckRoom)
