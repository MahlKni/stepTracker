addon.name      = "StepTracker";
addon.author    = "Mahlkni";
addon.version   = "0.1";
addon.desc      = "Track dancer step levels";
addon.link      = "https://github.com/MahlKni/stepTracker/";

require "common";
local fonts = require("fonts");
local settings = require('settings');
local defaults = T{
	visible = true,
    displayTime = 15,
    color = 0xFFFFFFFF,
    mobcolor = '|cFFFFFFFF|',
	green = '|cFF00FF00|';
    red = '|cFFFF0000|',
    yellow = '|cFFFFFF00|',
	font_family = 'Arial',
	font_height = 12,
	color = 0xFFFFFFFF,
	position_x = 500,
	position_y = 500,
	background = T{
		visible = true,
		color = 0xFF000000,
	}
};
local display = T{};
local osd = T{};
local mobs = T{};-- [id] = {name,StepName,+StepCount}
local Towns = T{'Tavnazian Safehold','Al Zahbi','Aht Urhgan Whitegate','Nashmau','Southern San d\'Oria [S]','Bastok Markets [S]','Windurst Waters [S]','San d\'Oria-Jeuno Airship','Bastok-Jeuno Airship','Windurst-Jeuno Airship','Kazham-Jeuno Airship','Southern San d\'Oria','Northern San d\'Oria','Port San d\'Oria','Chateau d\'Oraguille','Bastok Mines','Bastok Markets','Port Bastok','Metalworks','Windurst Waters','Windurst Walls','Port Windurst','Windurst Woods','Heavens Tower','Ru\'Lude Gardens','Upper Jeuno','Lower Jeuno','Port Jeuno','Rabao','Selbina','Mhaura','Kazham','Norg','Mog Garden','Celennia Memorial Library','Western Adoulin','Eastern Adoulin'};
local area = '';
local boxCount = 0;
local quickCount = 0;
local featherCount = 0;
local stutterCount = 0;

settings.register('settings', 'settings_update', function (s)
    if (s ~= nil) then
        osd = s;
    end
    settings.save();
end);

ashita.events.register('load', 'load_cb', function()
	osd = settings.load(defaults);
    
    display = fonts.new(osd);
end);

ashita.events.register('unload', 'unload_cb', function()
	settings.save();

    if (display ~= nil) then
		display:destroy();
	end
end);

ashita.events.register('text_in', 'text_in_cb', function(e)
    
	if e.message:contains('Quickstep') or e.message:contains('Step') then
		local index = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0);
        if index == nil then return end;
        local target = GetEntity(index);
        if AshitaCore:GetMemoryManager():GetEntity():GetType(index) ~= 2 then return end;
        local count = tonumber(string.match(e.message,'%d+'));
        start,finish = string.find(e.message,'%d+')
        local stepName = tostring(string.match(e.message,'%a+',finish))
		local boxCount
		local quickCount
		local featherCount
		local stutterCount
		if stepName == "Box" then
			boxCount = count
		elseif stepName == "Feather" then
			featherCount = count
		elseif stepName == "Stutter" then
			stutterCount = count
		else
			quickCount = count
		end
		
		mobs[index] = {target.Name, target.HPPercent, stepName, true, os.time(), boxCount , quickCount, featherCount, stutterCount};
        display.mobcolor = display.yellow;
        if AshitaCore:GetMemoryManager():GetEntity():GetType(index) ~= 2 then return end;              
        if not count or count == 0 then return; end
		if target == nil then return end;
	end
end);

ashita.events.register('d3d_present', 'present_cb', function ()
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    local t = 0;
    display.text = '';
    area = AshitaCore:GetResourceManager():GetString("zones.names", AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0));

	if (player:GetIsZoning() ~= 0) or (area == nil) or (Towns:contains(area)) then
        mobs = T{};
		return;
	end

    for k,v in pairs(mobs) do
        t = t + 1;
        
        if t == 1 then
            display.text = 'StepTracker Tracking Mobs: ';
        end
        
        local mob = GetEntity(k);
        if v[2] == 0 then
            display.text = display.text .. display.red .. '\n' .. v[1] .. '(' .. tostring(k) .. ') ' .. '  Box: ' .. tostring(v[6]).. '  Quick: ' .. tostring(v[7]) .. '  F: ' .. tostring(v[8]) .. '  Stutter: ' .. tostring(v[9]);
        else
            display.text = display.text .. display.mobcolor .. '\n' .. v[1] .. '(' .. tostring(k) .. ') ' .. '  Box: ' .. tostring(v[6]).. '  Quick: ' .. tostring(v[7]) .. '  F: ' .. tostring(v[8]) .. '  Stutter: ' .. tostring(v[9]);
        end
    end

	if display.position_x ~= osd.position_x or display.position_y ~= osd.position_y then--force settings save when simply dragging the text box
        osd.position_x = display.position_x;
        osd.position_y = display.position_y;
        settings.save();
    end

    update();
end);

function update()
    for k,v in pairs(mobs) do
        v[2] = AshitaCore:GetMemoryManager():GetEntity():GetHPPercent(k) or 0;
        
        if tonumber(('%2i'):fmt(math.sqrt(AshitaCore:GetMemoryManager():GetEntity():GetDistance(k)))) > 50 then v[2] = 0 end;
        
        for m = 0, 17 do
            if AshitaCore:GetMemoryManager():GetParty():GetMemberName(m) == v[1] then
                mobs[k] = nil
            end
        end

        if v[2] == 0 and v[4] then 
            v[4] = not v[4]
            v[5] = os.time();
        end

        if os.time() - v[5] > osd.displayTime and v[2] == 0 then mobs[k] = nil
		boxCount = 0;
		quickCount = 0;
		featherCount = 0;
		stutterCount = 0;
		end;
    end
end

