
if GetLocale() ~= "esES" and GetLocale() ~= "esMX" then return end
local _, tbl = ...
local L = tbl.locale

--@localization(locale="esES", format="lua_additive_table", handle-unlocalized="comment")@