local Feat = require("api.Feat")
local Enum = require("api.Enum")
local Const = require("api.Const")
local Rand = require("api.Rand")
local Gui = require("api.Gui")
local Skill = require("mod.elona_sys.api.Skill")
local Map = require("api.Map")
local I18N = require("api.I18N")
local Chara = require("api.Chara")
local Save = require("api.Save")

local Gardening = {}

function Gardening.plant_seed(seed, chara, x, y)
   -- >>>>>>>> elona122/shade2/action.hsp:2274 *item_seed ..
   x = x or chara.x
   y = y or chara.y

   local map = chara:current_map()

   if Map.is_world_map(map) or map:has_type{"town", "guild"} then
      Gui.mes("action.plant.cannot_plant_it_here")
      return false
   end

   local feats = Feat.at(x, y)
   if feats:length() > 0 then
      Gui.mes("action.plant.cannot_plant_it_here")
      return false
   end

   local is_crop_tile = map:tile(x, y).role == Enum.TileRole.Crop
   local plant_id = seed.params.seed_plant_id
   data["elona.plant"]:ensure(plant_id)

   local plant = assert(Feat.create("elona.plant", x, y, { force = true }, map))
   plant.plant_id = plant_id
   Gardening.recalc_plant_growth_time(plant, chara, is_crop_tile)

   local mes
   if is_crop_tile then
      mes = I18N.get("action.plant.on_field", seed:build_name(1))
   else
      mes = I18N.get("action.plant.execute", seed:build_name(1))
   end
   Gui.mes(mes)
   Gui.play_sound("base.bush1", x, y)
   seed:remove(1)

   Skill.gain_skill_exp(chara, "elona.gardening", 300)

   return true
   -- <<<<<<<< elona122/shade2/action.hsp:2292 	goto *turn_end ..
end

function Gardening.grow_plants(map, chara, days_passed)
   map = map or Map.current()
   chara = chara or Chara.player()
   days_passed = days_passed or 1

   -- >>>>>>>> elona122/shade2/map.hsp:2236 			repeat mHeight ..
   local is_plant = function(feat) return feat._id == "elona.plant" end

   for _, feat in Feat.iter(map):filter(is_plant) do
      for _ = 1, days_passed do
         if feat.plant_growth_stage >= 2 then
            break
         end
         local is_crop_tile = map:tile(feat.x, feat.y).role == Enum.TileRole.Crop
         Gardening.grow_plant(feat, chara, is_crop_tile)
      end
   end
   -- <<<<<<<< elona122/shade2/map.hsp:2251 			loop ..
end

function Gardening.grow_plant(plant, chara, is_crop_tile)
   -- >>>>>>>> elona122/shade2/action.hsp:2294 *item_seedGrowth ..
   plant.plant_time_to_growth_days = plant.plant_time_to_growth_days - 1
   if plant.plant_time_to_growth_days % 50 == 0 then
      if plant.plant_time_to_growth_days >= 50 then
         -- >= 50 means wilted
         plant.plant_growth_stage = 3
         plant.image = "elona.feat_plant_" .. plant.plant_growth_stage
      else
         plant.plant_growth_stage = math.min(plant.plant_growth_stage + 1, 3)
         Gardening.recalc_plant_growth_time(plant, chara, is_crop_tile)
      end
   end
   -- <<<<<<<< elona122/shade2/action.hsp:2299 	return ..
end

function Gardening.recalc_plant_growth_time(plant, chara, is_crop_tile)
   plant.plant_growth_stage = plant.plant_growth_stage or 0
   plant.image = "elona.feat_plant_" .. plant.plant_growth_stage
   local time_to_growth = Gardening.calc_plant_time_to_growth_days(plant, chara, is_crop_tile)
   plant.plant_time_to_growth_days = time_to_growth
end

function Gardening.calc_gardening_difficulty(plant, chara, is_crop_tile)
   local plant_data = data["elona.plant"]:ensure(plant.plant_id)
   local difficulty = plant_data.growth_difficulty or 10

   if not is_crop_tile then
      difficulty = difficulty * 3 / 2
   end

   -- TODO weather
   local is_raining = false
   if plant.plant_growth_stage == 0 and not is_raining then
      difficulty = difficulty * 2
   end

   return math.floor(difficulty)
end

function Gardening.calc_plant_time_to_growth_days(plant, chara, is_crop_tile)
   local time_to_growth = Const.PLANT_GROWTH_DAYS + Rand.rnd(Const.PLANT_GROWTH_DAYS)

   local chance = Gardening.calc_gardening_difficulty(plant, chara, is_crop_tile)

   if chara:skill_level("elona.gardening") < Rand.rnd(chance+1) or Rand.one_in(20) then
      -- >= 50 means wilted
      time_to_growth = time_to_growth + 50
   end

   return time_to_growth
end

function Gardening.calc_regrowth_difficulty(plant, chara, is_crop_tile)
   local plant_data = data["elona.plant"]:ensure(plant.plant_id)
   local difficulty = plant_data.regrowth_difficulty or 15

   if not is_crop_tile then
      difficulty = difficulty * 2
   end

   -- TODO weather
   local is_raining = false
   if plant.plant_growth_stage == 0 and not is_raining then
      difficulty = difficulty * 2
   end

   return difficulty
end

function Gardening.regrow_plant(plant, chara, is_crop_tile)
   -- >>>>>>>> elona122/shade2/action.hsp:2315 *item_seedRegrowth ..
   local difficulty = Gardening.calc_regrowth_difficulty(plant, chara, is_crop_tile)
   if chara:skill_level("elona.gardening") < Rand.rnd(difficulty+1) or Rand.one_in(5) then
      return false
   end

   local map = assert(chara:current_map())
   local new_plant = assert(Feat.create("elona.plant", plant.x, plant.y, { force = true }, map))
   new_plant.plant_id = plant.plant_id
   new_plant.plant_growth_stage = 0
   new_plant.plant_time_to_growth_days = 0
   Gardening.recalc_plant_growth_time(new_plant, chara, is_crop_tile)
   Gui.mes_c("action.plant.new_plant_grows", "Green")
   plant:remove_ownership()

   return true
   -- <<<<<<<< elona122/shade2/action.hsp:2329 	return  ..
end

function Gardening.get_plant(plant, chara)
   -- >>>>>>>> elona122/shade2/command.hsp:3198 			if feat<tile_plant+2 : txt lang("芽を摘み取った。","You ..
   if plant.plant_growth_stage < 2 then
      Gui.mes("action.get.plant.young")
      plant:remove_ownership()
      return true
   elseif plant.plant_growth_stage == 3 then
      Gui.mes("action.get.plant.dead")
      plant:remove_ownership()
      return true
   end

   -- TODO inventory space
   local has_space = true
   if not has_space then
      Gui.mes("ui.inv.common.inventory_is_full")
      return false
   end

   Gardening.harvest_plant(plant, chara)

   local map = chara:current_map()
   local is_crop_tile = map:tile(chara.x, chara.y).role == Enum.TileRole.Crop
   Gardening.regrow_plant(plant, chara, is_crop_tile)

   -- TODO
   if plant.plant_id == "elona.artifact" then
      Save.autosave()
   end

   chara:refresh_weight()

   return true
   -- <<<<<<<< elona122/shade2/command.hsp:3206 			goto *turn_end ..
end

function Gardening.harvest_plant(plant, chara)
   -- >>>>>>>> elona122/shade2/action.hsp:2332 *item_seedPick ..
   Skill.gain_skill_exp(chara, "elona.gardening", 75)

   Gui.play_sound("base.bush1", plant.x, plant.y)
   plant:emit("elona.on_harvest_plant", {chara=chara})
   plant:remove_ownership()
   -- <<<<<<<< elona122/shade2/action.hsp:2351 	return ..
end

return Gardening
