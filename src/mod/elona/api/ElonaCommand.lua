local Draw = require("api.Draw")
local Item = require("api.Item")
local Map = require("api.Map")
local ElonaAction = require("mod.elona.api.ElonaAction")
local Gui = require("api.Gui")
local Input = require("api.Input")
local Pos = require("api.Pos")
local Rand = require("api.Rand")
local UiTheme = require("api.gui.UiTheme")
local World = require("api.World")

local ElonaCommand = {}

function ElonaCommand.bash(player)
   Gui.mes("Which direction?")
   local dir = Input.query_direction()

   if not dir then
      Gui.mes("Okay, then.")
      return "player_turn_query"
   end

   local result = ElonaAction.bash(player, Pos.add_direction(dir, player.x, player.y))

   if not result then
      return "player_turn_query"
   end

   return "turn_end"
end

function ElonaCommand.do_eat(player, item)
   if player:calc("nutrition") > 10000 then
      Gui.mes("too bloated.")
      Gui.update_screen()
      return "player_turn_query"
   end

   local result = ElonaAction.eat(player, item)

   if not result then
      return "player_turn_query"
   end

   return "turn_end"
end

function ElonaCommand.eat(player)
   return Input.query_inventory(player, "inv_eat")
end

function ElonaCommand.do_dig(player, x, y)
   if player.stamina < 0 then
      Gui.mes("too exhausted")
      return false
   end

   player:start_activity("elona.dig_wall", {x = x, y = y})
   return true
end

function ElonaCommand.dig(player)
   Gui.mes("Which direction?")
   local dir = Input.query_direction()

   if not dir then
      Gui.mes("Okay, then.")
      return "player_turn_query"
   end

   local x, y = Pos.add_direction(dir, player.x, player.y)

   if x == player.x and y == player.y then
      Gui.mes("dig spot")
      return "player_turn_query"
   end

   -- Don't allow digging into water.
   local tile = player:current_map():tile(x, y)
   local can_dig = tile.is_solid and tile.is_opaque

   if not can_dig then
      Gui.mes("it is impossible.")
      return "player_turn_query"
   end

   Gui.update_screen()
   local result = ElonaCommand.do_dig(player, x, y)

   if not result then
      return "player_turn_query"
   end

   return "turn_end"
end

function ElonaCommand.increment_sleep_potential(player)
   local stats = data["base.skill"]:iter():filter(function(s) return s.skill_type == "stat" end):extract("_id")
   local levels = 0
   for _, id in stats:unwrap() do
      levels = levels + player:base_skill_level(id)
   end
   levels = math.clamp(math.floor(levels / 6), 10, 1000)
   local exp = levels * levels * levels / 10
   local bed_quality = 1 -- TODO
   player.sleep_experience = math.floor(player.sleep_experience * bed_quality / 100)
   local grown_count = 0
   while true do
      if player.sleep_experience >= exp then
         player.sleep_experience = player.sleep_experience - exp
      elseif grown_count ~= 0 then
         break
      end
      player:mod_base_skill_potential(10 + Rand.rnd(8), 1)
      grown_count = grown_count + 1
      if grown_count > 6 then
         if Rand.one_in(5) then
            player.sleep_experience = 0
            break
         end
      end
   end

   return grown_count
end

function ElonaCommand.do_sleep(player, bed, params)
   params = params or { no_animation = false, sleep_hours = nil }

   -- TODO is quest

   if player:calc("catches_god_signal") then
   end

   if not params.no_animation then
      Gui.play_music("elona.mcCoda")
      Gui.mes_halt()
   end

   local bg = UiTheme.load_asset("bg_night")

   if not params.no_animation then
      Draw.run(function(state)
            if state.i > 20 then
               bg:draw(0, 0, Draw.get_width(), Draw.get_height(), { 255, 255, 255 })
               return nil
            end
            bg:draw(0, 0, Draw.get_width(), Draw.get_height(), { 255, 255, 255, state.i * 10 })
            Draw.wait(20 * 10)
            return { i = state.i + 1 }
               end, { i = 0 }, true)
   end

   for _, chara in player:iter_party() do
      chara:emit("elona.on_sleep")
   end

   local time_slept = params.sleep_hours or 7 + Rand.rnd(5)

   for _ = 1, time_slept do
      World.pass_time_in_seconds(60 * 60, "hour")
      save.base.date.minute = 0
      save.elona_sys.awake_hours = 0

      if not params.no_animation then
         Draw.run(function()
               bg:draw(0, 0, Draw.get_width(), Draw.get_height(), { 255, 255, 255 })
               Draw.wait(20 * 25)
         end)
      end
   end

   -- TODO gene

   if not params.no_animation then
      Draw.run(function()
            bg:draw(0, 0, Draw.get_width(), Draw.get_height(), { 255, 255, 255 })
      end)
   end

   ElonaCommand.wake_up_everyone()

   local adj = 1
   if player:has_trait("elona.slow_digestion") then
      adj = 2
   end
   player.nutrition = player.nutrition - math.floor(1500 / adj)
   Gui.mes("Slept for " .. time_slept .. ".", "Green")

   local add_potential = true

   if not Item.is_alive(bed) then
      add_potential = false
   else
      local is_bed = true -- TODO
      if not is_bed then
         add_potential = false
      end
   end

   if add_potential then
      local count = ElonaCommand.increment_sleep_potential(player)
      Gui.mes("Quality is good: grew " .. count, "Green")
   else
      Gui.mes("Quality is so-so.")
   end

   if not params.no_animation then
      Gui.mes_halt()
      Gui.play_music()
   end
   -- TODO autosave
   -- TODO shop
end

function ElonaCommand.wake_up_everyone(map)
   map = map or Map.current()
   local hour = save.base.date.hour
   if hour >= 7 or hour <= 22 then
      for _, chara in Map.iter_charas() do
         if not chara:is_ally() and chara:has_effect("elona.sleep") then
            if Rand.one_in(10) then
               chara:remove_effect("elona.sleep")
            end
         end
      end
   end
end

return ElonaCommand