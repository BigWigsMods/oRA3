# oRA3 Cooldowns Developer Notes

This is a quick overview of how to get a new display to work with oRA3.

All available spells have their cooldowns tracked while you are in a group and expire times are saved in a global db to be restored on reload/disconnect/etc.

On startup (ie, joining a group or opening settings) the roster is checked and callbacks are fired for all spells.

## DB structure:

- `display.defaultDB`: optional, your table of default db values
- `display.db`: set by oRA, table of db values
- `display.spellDB`: set by oRA, lookup table of enabled spell ids
- `display.filterDB`: set by oRA, table of db values

db.showDisplay and db.lockDisplay are used to control the display (don't need to be included in defaultDB)


## Interface:

Required methods:
- `display:Show()`
- `display:Hide()`
- `display:Lock()`
- `display:Unlock()`

Optional methods:
 - `display:TestCooldown(name, class, spellId)`: called to show test cooldowns on the display
 - `display:Delete()`: called when deleting a display
 - `display:OnSpellOptionChanged(spellId, value)`: called when a spell is enabled or disabled for a display
 - `display:OnFilterOptionChanged(key, value)`: called when a filter is enabled or disabled for a display
 - `display:GetPosition()`: called when converting between display types to save the position
 - `display:SetPosition(x, y, width, height)`: called when converting between display types to restore the position


## Callbacks:

 - `OnStartup()`: fired when joining a group or opening the settings panel while not in a group
 - `OnShutdown()`: fired when leaving a group or closing the settings panel while not in a group
 - `oRA3CD_CooldownReady(guid, name, class, spellId)`: fired when a spell comes off cooldown
 - `oRA3CD_StartCooldown(guid, name, class, spellId, cooldown)`: fired when a spell is used
 - `oRA3CD_UpdateCharges(guid, name, class, spellId, cooldown, charges, maxCharges, recharged)`: fired when a charge is used or comes off cooldown (fired after an accompanying oRA3CD_StartCooldown or oRA3CD_CooldownReady)
 - `oRA3CD_StopCooldown(guid, spelld)`: fired to stop cds for a player (left group) or a spell (encounter reset), only one arg is required
 - `oRA3CD_UpdatePlayer(guid, name)`: fired when player's alive, connection, or range status changes

Note: displays can "embed" RegisterEvent, UnregisterEvent, and UnregisterAllEvents from oRA3 for event handling (see Displays/Bars.lua for an example)


## API:

 `oRA3CD:RegisterDisplayType(typeName, displayName, displayDescription, displayVersion, constructorFunc, optionsTable)`: Registers a display constructor which returns a new instance of the display.


 - `oRA3CD:GetPlayerFromGUID(guid)`: returns player name and class
 - `oRA3CD:CheckFilter(display, player)`: returns true is a player's spells should be shown
 - `oRA3CD:IsSpellUsable(guid, spellId)`: returns true/false for if a player can cast a spell
 - `oRA3CD:GetCooldown(guid, spellId)`: returns the full cooldown
 - `oRA3CD:GetRemainingCooldown(guid, spellId)`: returns the remaining cooldown or 0
 - `oRA3CD:GetCharges(guid, spellId)`: returns the numbers of charges or 0
 - `oRA3CD:GetRemainingCharges(guid, spellId)`: returns the remaining number of charges or 0
 - `oRA3CD:GetRemainingChargeCooldown(guid, spellId)`: returns the next recharge or full cooldown


## Container:

`oRA3CD:AddContainer(display)`: Embed a container that handles resizing and positioning

#### Methods added to display:

 - `display:Show()`
 - `display:Hide()`
 - `display:Lock()`
 - `display:Unlock()`
 - `display:Setup()`
 - `display:Delete()`
 - `display:GetContainer()`: returns the container frame
 - `display:GetPosition()`: returns the x position, y position, width, and height of the container
 - `display:SetPosition(x, y, width, height)`: sets the position and size of the container

as well as `IsShown`, `GetWidth`, `GetHeight`, `GetSize`, `GetTop`, `GetBottom`, `GetLeft`, `GetRight` that reference the container

#### Callbacks: (optional)

 - `display:OnShow()`
 - `display:OnHide()`
 - `display:OnLock()`
 - `display:OnUnlock()`
 - `display:OnDelete()`
 - `display:OnResize(width, height)`
 - `display:OnSetup(container)`: called after the container is initialized, before it's positioned and sized

