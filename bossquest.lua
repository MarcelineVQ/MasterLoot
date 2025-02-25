-- These are quest items that once gained by the lootmaster, will no longer show on corpse to loot or aren't shown due to not being on the right faction. You can should comment out the quest items you haven't completed yet. 

bossquest = {}

function bossquest:fakeitems(faction)
    -- boss_quest["Forest Lurker"] = {"\124cffa335ee\124Hitem:22520:0:0:0:0:0:0:0:0\124h[The Phylactery of Kel'Thuzad]\124h\124r"} --test subject
    -- boss_quest["Sawtooth Crocolisk"] = {"\124cffa335ee\124Hitem:22520:0:0:0:0:0:0:0:0\124h[The Phylactery of Kel'Thuzad]\124h\124r","\124cffa335ee\124Hitem:61652:0:0:0:0:0:0:0:0\124h[Claw of Erennius]\124h\124r"} --test subject
    -- boss_quest["Deathstrike Tarantula"] = {"\124cffa335ee\124Hitem:19003:0:0:0:0:0:0:0:0\124h[Head of Nefarian (Alliance)]\124h\124r"} --test subject
    boss_quest["Kel'Thuzad"] = {"\124cffa335ee\124Hitem:22520:0:0:0:0:0:0:0:0\124h[The Phylactery of Kel'Thuzad]\124h\124r"}
    boss_quest["Erennius"] = {"\124cffa335ee\124Hitem:61652:0:0:0:0:0:0:0:0\124h[Claw of Erennius]\124h\124r"}
    boss_quest["Solnius"] = {"\124cffa335ee\124Hitem:61444:0:0:0:0:0:0:0:0\124h[Smoldering Dream Essence]\124h\124r","\124cffa335ee\124Hitem:61215:0:0:0:0:0:0:0:0\124h[Head of Solnius]\124h\124r"} -- Smoldering doesn't always drop
    boss_quest["Ossirian the Unscarred"] = {"\124cffa335ee\124Hitem:21220:0:0:0:0:0:0:0:0\124h[Head of Ossirian the Unscarred]\124h\124r"}
    
    -- always lootable now
    -- if (faction == "Alliance") then
    --     boss_quest["Nefarian"] = {"\124cffa335ee\124Hitem:19002:0:0:0:0:0:0:0:0\124h[Head of Nefarian (Horde)]\124h\124r"} -- So Alliance ML can roll horde head
    --     elseif (faction == "Horde") then
    --     boss_quest["Nefarian"] = {"\124cffa335ee\124Hitem:19003:0:0:0:0:0:0:0:0\124h[Head of Nefarian (Alliance)]\124h\124r"} -- So Horde ML can roll Alliance head
    -- end
end

function bossquest:faketooltip()
    -- caching fakeitems
    for bossName, items in pairs(boss_quest) do	
        if type(items) == "table" then		
            for lootcount = 1, getn(items) do
                fakelink = items[lootcount]
                local _, _, itemIdStr = string.find(fakelink, "item:(%d+)")
                -- print(itemIdStr)
                local itemId = tonumber(itemIdStr)
                GameTooltip:SetHyperlink("item:" .. itemId .. ":0:0:0")
                DEFAULT_CHAT_FRAME:AddMessage("|cff20b2aa->|r |cffffd700Quest item loaded: ".. fakelink.. "|r|cffead454")
            end
	    end
    end
end