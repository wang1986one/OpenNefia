local Anim = require("mod.elona_sys.api.Anim")
local Chara = require("api.Chara")
local Draw = require("api.Draw")
local Effect = require("mod.elona.api.Effect")
local ElonaPos = require("mod.elona.api.ElonaPos")
local Pos = require("api.Pos")
local Gui = require("api.Gui")
local I18N = require("api.I18N")
local Rand = require("api.Rand")
local SkillCheck = require("mod.elona.api.SkillCheck")
local Queue = require("api.Queue")

local RANGE_BOLT = 6
local RANGE_BALL = 2
local RANGE_BREATH = 5

local function is_in_screen(tx, ty)
   local sx, sy = Gui.tile_to_visible_screen(tx, ty)
   local msg_y = Gui.message_window_y()
   return sy >= 0 and sy <= msg_y
      and sx >= 0 and sx <= Draw.get_width()
end

local function make_sick(target, chance)
   if Rand.one_in(chance or 1) then
      Gui.mes_visible("food.cursed_drink", target.x, target.y, target)
      target:apply_effect("elona.sick", 200)
   end
end

local function mp_cost_constant(skill_entry, chara)
   return skill_entry.cost
end


-- attack (spore)

-- bolt

local function make_bolt(opts)
   local id = opts._id
   local full_id = "elona.spell_" .. id
   local element_id = opts.element_id

   data:add {
      _id = "spell_" .. id,
      _type = "base.skill",

      type = "spell",
      effect_id = "elona." .. id,
      related_skill = "elona.stat_magic",
      cost = opts.cost,
      range = RANGE_BOLT,
      difficulty = opts.difficulty,
      target_type = "target_or_location"
   }

   data:add {
      _id = id,
      _type = "elona_sys.magic",
      elona_id = opts.elona_id,

      type = "action",
      params = {
         "source"
      },

      dice = function(self, params)
         local level = params.source:skill_level(full_id)
         return {
            x = (opts.dice_x and opts.dice_x(params.power, level)) or 0,
            y = (opts.dice_y and opts.dice_y(params.power, level)) or 0,
            bonus = (opts.dice_bonus and opts.dice_bonus(params.power, level)) or 0,
            element_power = (opts.dice_element_power and opts.dice_element_power(params.power, level)) or 0
         }
      end,

      cast = function(self, params)
         local source = params.source
         local map = params.source:current_map()
         local sx = params.source.x
         local sy = params.source.y
         local positions, success = ElonaPos.make_route(sx, sy, params.x, params.y, map)
         if not success then
            return false
         end

         local element, color, sound
         if element_id then
            element = data["base.element"]:ensure(element_id)
            color = element.color
            sound = element.sound
         end

         local cb = Anim.bolt(positions, color, sound, sx, sy, params.x, params.y, params.range, map)
         Gui.start_draw_callback(cb)

         local tx = sx
         local ty = sy

         for i = 0, 19 do
            local pos = positions[(i%#positions)+1]
            local dx = pos[1]
            local dy = pos[2]
            tx = tx + dx
            ty = ty + dy

            if i <= #positions or (map:is_in_bounds(tx, ty) and map:can_see_through(tx, ty) and is_in_screen(tx, ty)) then
               if Pos.dist(sx, sy, tx, ty) > params.range then
                  break
               end

               if sx ~= tx or sy ~= ty then
                  if element and element.on_damage_tile then
                     element:on_damage_tile(tx, ty, source)
                  end
                  local target = Chara.at(tx, ty, map)
                  if target and target ~= source then
                     -- TODO riding
                     local dice = self:dice(params)
                     local damage = Rand.roll_dice(dice.x, dice.y, dice.bonus)

                     local success, damage = SkillCheck.handle_control_magic(source, target, damage)
                     if not success then
                        local tense = "enemy"
                        if not target:is_ally() then
                           tense = "ally"
                        end
                        if tense == "ally" then
                           Gui.mes_visible("magic.bolt.other", tx, ty, target)
                        else
                           Gui.mes_visible("magic.bolt.ally", tx, ty, target)
                        end
                        target:damage_hp(damage,
                                         source,
                                         {
                                            element = element_id,
                                            element_power = dice.element_power,
                                            message_tense = tense,
                                            no_attack_text = true,
                                            is_third_person = true
                        })
                     end
                  end
               end
            end
         end
         return true
      end
   }
end

make_bolt {
    _id = "ice_bolt",
    element_id = "elona.cold",
    elona_id = 419,
    dice_x = function(p, l) return p/50+1+l/20 end,
    dice_y = function(p, l) return p/26+4 end,
    bonus = nil,
    element_power = function(p, l) return 180+p/4 end,
    cost = 10,
    difficulty = 220
}

make_bolt {
    _id = "fire_bolt",
    element_id = "elona.fire",
    elona_id = 420,
    dice_x = function(p, l) return p/50+1+l/20 end,
    dice_y = function(p, l) return p/26+4 end,
    bonus = nil,
    element_power = function(p, l) return 180+p/4 end,
    cost = 10,
    difficulty = 220
}

make_bolt {
    _id = "lightning_bolt",
    element_id = "elona.lightning",
    elona_id = 421,
    dice_x = function(p, l) return p/50+1+l/20 end,
    dice_y = function(p, l) return p/26+4 end,
    bonus = nil,
    element_power = function(p, l) return 180+p/4 end,
    cost = 10,
    difficulty = 220
}

make_bolt {
    _id = "darkness_bolt",
    element_id = "elona.darkness",
    elona_id = 422,
    dice_x = function(p, l) return p/50+1+l/20 end,
    dice_y = function(p, l) return p/25+4 end,
    bonus = nil,
    element_power = function(p, l) return 180+p/4 end,
    cost = 12,
    difficulty = 350
}

make_bolt {
    _id = "mind_bolt",
    element_id = "elona.mind",
    elona_id = 423,
    dice_x = function(p, l) return p/50+1+l/20 end,
    dice_y = function(p, l) return p/25+4 end,
    bonus = nil,
    element_power = function(p, l) return 180+p/4 end,
    cost = 12,
    difficulty = 350
}

-- arrow

local function make_arrow(opts)
   local id = opts._id
   local full_id = "elona.spell_" .. opts._id

   data:add {
      _id = "spell_" .. id,
      _type = "base.skill",

      type = "spell",
      effect_id = "elona." .. id,
      related_skill = "elona.stat_magic",
      cost = opts.cost,
      range = RANGE_BOLT,
      difficulty = opts.difficulty,
      target_type = "enemy",
      is_rapid_magic = true
   }

   data:add {
      _id = id,
      _type = "elona_sys.magic",
      elona_id = opts.elona_id,

      type = "skill",
      params = {
         "source",
         "target"
      },

      dice = function(self, params)
         local level = params.source:skill_level(full_id)
         return {
            x = (opts.dice_x and opts.dice_x(params.power, level)) or 0,
            y = (opts.dice_y and opts.dice_y(params.power, level)) or 0,
            bonus = (opts.dice_bonus and opts.dice_bonus(params.power, level)) or 0,
            element_power = (opts.dice_element_power and opts.dice_element_power(params.power, level)) or 0
         }
      end,

      cast = function(self, params)
         local source = params.source
         local target = params.target
         local sx = params.source.x
         local sy = params.source.y
         local tx = params.target.x
         local ty = params.target.y

         local element = data["base.element"]:ensure(opts.element_id)
         local color = element.color
         local sound = element.sound

         if source:is_in_fov() then
            local cb = Anim.ranged_attack(sx, sy, tx, ty, "elona.item_projectile_magic_arrow", color, "base.arrow1", sound)
            Gui.start_draw_callback(cb)
         end

         local dice = self:dice(params)
         local damage = Rand.roll_dice(dice.x, dice.y, dice.bonus)

         local tense = "enemy"
         if not target:is_ally() then
            tense = "ally"
         end
         if tense == "ally" then
            Gui.mes_visible("magic.arrow.other", tx, ty, target)
         else
            Gui.mes_visible("magic.ball.ally", tx, ty, target)
         end

         target:damage_hp(damage,
                          source,
                          {
                             element = opts.element_id,
                             element_power = params.element_power,
                             message_tense = tense,
                             no_attack_text = true,
                             is_third_person = true
         })

         return true
      end
   }
end

make_arrow {
   _id = "magic_dart",
   elona_id = 414,
   element_id = "elona.magic",
   dice_x = function(p, l) return p/125+2+l/50 end,
   dice_y = function(p, l) return p/60+9 end,
   bonus = nil,
   element_power = function(p, l) return 100+p/4 end,
   cost = 5,
   difficulty = 110,
}

make_arrow {
   _id = "nether_arrow",
   elona_id = 415,
   element_id = "elona.nether",
   dice_x = function(p, l) return p/70+1+l/18 end,
   dice_y = function(p, l) return p/25+8 end,
   bonus = nil,
   element_power = function(p, l) return 200+p/3 end,
   cost = 8,
   difficulty = 400,
}

make_arrow {
   _id = "nerve_arrow",
   elona_id = 416,
   element_id = "elona.nerve",
   dice_x = function(p, l) return p/70+1+l/18 end,
   dice_y = function(p, l) return p/25+8 end,
   bonus = nil,
   element_power = function(p, l) return 200+p/3 end,
   cost = 10,
   difficulty = 650,
}

make_arrow {
   _id = "chaos_eye",
   elona_id = 417,
   element_id = "elona.chaos",
   dice_x = function(p, l) return p/70+1+l/18 end,
   dice_y = function(p, l) return p/25+8 end,
   bonus = nil,
   element_power = function(p, l) return 200+p/3 end,
   cost = 10,
   difficulty = 400,
}

make_arrow {
   _id = "dark_eye",
   elona_id = 418,
   element_id = "elona.darkness",
   dice_x = function(p, l) return p/80+1+l/18 end,
   dice_y = function(p, l) return p/25+8 end,
   bonus = nil,
   element_power = function(p, l) return 200+p/3 end,
   cost = 10,
   difficulty = 200,
}

make_arrow {
   _id = "crystal_spear",
   elona_id = 459,
   element_id = "elona.magic",
   dice_x = function(p, l) return p/100+3+l/25 end,
   dice_y = function(p, l) return p/40+12 end,
   bonus = nil,
   element_power = function(p, l) return 100+p/4 end,
   cost = 24,
   difficulty = 950,
}

-- ball

local function make_ball(opts)
   local type = opts.type or "spell"
   local full_id = "elona."  .. type .. "_" .. opts._id

   data:add {
      _id = type .. "_" .. opts._id,
      _type = "base.skill",

      type = type,
      effect_id = "elona." .. opts._id,
      related_skill = opts.related_skill,
      cost = opts.cost,
      range = RANGE_BALL,
      difficulty = opts.difficulty,
      target_type = "self_or_nearby",
      ai_check_ranged_if_self = true
   }

   data:add {
      _id = opts._id,
      _type = "elona_sys.magic",
      elona_id = opts.elona_id,

      params = {
         "source"
      },

      dice = function(self, params)
         local level = params.source:skill_level(full_id)
         return {
            x = (opts.dice_x and opts.dice_x(params.power, level)) or 0,
            y = (opts.dice_y and opts.dice_y(params.power, level)) or 0,
            bonus = (opts.dice_bonus and opts.dice_bonus(params.power, level)) or 0,
            element_power = (opts.dice_element_power and opts.dice_element_power(params.power, level)) or 0
         }
      end,

      cast = function(self, params)
         local source = params.source
         local map = params.source:current_map()
         local x = params.source.x
         local y = params.source.y

         local positions = ElonaPos.make_ball(x, y, params.range, map)

         local element
         if opts.element_id then
            element = data["base.element"]:ensure(opts.element_id)
            local color = element.color
            local sound = element.sound

            local cb = Anim.ball(positions, color, sound, x, y, map)
            Gui.start_draw_callback(cb)
         end

         for _, pos in ipairs(positions) do
            local tx = pos[1]
            local ty = pos[2]

            local target = Chara.at(tx, ty)

            if target then
               opts.ball_cb(self, x, y, tx, ty, source, target, element, params)
            end
         end

         return true
      end
   }
end

local function ball_cb_elemental(self, x, y, tx, ty, source, target, element, params)
   if x == tx and y == ty then
      return
   end

   -- TODO riding
   if element and element.on_damage_tile then
      element:on_damage_tile(tx, ty, source)
   end

   local dice = self:dice(params)
   local damage = Rand.roll_dice(dice.x, dice.y, dice.bonus) * 100 / (75 + Pos.dist(tx, ty, x, y) * 25)

   local success, damage = SkillCheck.handle_control_magic(source, target, damage)
   if not success then
      local tense = "enemy"
      if not target:is_ally() then
         tense = "ally"
      end
      if tense == "ally" then
         Gui.mes_visible("magic.ball.other", tx, ty, target)
      else
         Gui.mes_visible("magic.ball.ally", tx, ty, target)
      end

      target:damage_hp(damage,
                       source,
                       {
                          element = element._id,
                          element_power = params.element_power,
                          message_tense = tense,
                          no_attack_text = true,
                          is_third_person = true
      })
   end
end

make_ball {
   _id = "ice_ball",
   elona_id = 431,
   related_skill = "elona.stat_magic",
   element_id = "elona.cold",
   dice_x = function(p,l) return p/100+1+l/20 end,
   dice_y = function(p,l) return p/15+2 end,
   bonus = nil,
   element_power = function(p,l) return 150+p/5 end,
   cost = 16,
   difficulty = 450,
   ball_cb = ball_cb_elemental
}

make_ball {
   _id = "fire_ball",
   elona_id = 432,
   related_skill = "elona.stat_magic",
   element_id = "elona.fire",
   dice_x = function(p,l) return p/100+1+l/20 end,
   dice_y = function(p,l) return p/15+2 end,
   bonus = nil,
   element_power = function(p,l) return 150+p/5 end,
   cost = 16,
   difficulty = 450,
   ball_cb = ball_cb_elemental
}

make_ball {
   _id = "chaos_ball",
   elona_id = 433,
   related_skill = "elona.stat_magic",
   element_id = "elona.chaos",
   dice_x = function(p,l) return p/80+1+l/20 end,
   dice_y = function(p,l) return p/12+2 end,
   bonus = nil,
   element_power = function(p,l) return 150+p/5 end,
   cost = 20,
   difficulty = 1000,
   ball_cb = ball_cb_elemental
}

make_ball {
   _id = "raging_roar",
   elona_id = 434,
   related_skill = "elona.stat_magic",
   element_id = "elona.sound",
   dice_x = function(p,l) return p/80+1+l/20 end,
   dice_y = function(p,l) return p/12+2 end,
   bonus = nil,
   element_power = function(p,l) return 150+p/5 end,
   cost = 18,
   difficulty = 700,
   ball_cb = ball_cb_elemental
}

make_ball {
   _id = "magic_storm",
   elona_id = 435,
   related_skill = "elona.stat_magic",
   element_id = "elona.magic",
   dice_x = function(p,l) return p/100+1+l/25 end,
   dice_y = function(p,l) return p/18+2 end,
   bonus = nil,
   element_power = function(p,l) return 100 end,
   cost = 40,
   difficulty = 1400,
   ball_cb = ball_cb_elemental
}

local function ball_cb_healing_rain(self, x, y, tx, ty, source, target, element, params)
   if source:reaction_towards(target) >= 0 then
      local cb = Anim.heal(tx, ty, "base.heal_effect", "base.heal1", 5)
      Gui.start_draw_callback(cb)
      Gui.mes_visible("damage.is_healed", target.x, target.y, target)
      -- Magic.cast("")
   end
end

make_ball {
   _id = "healing_rain",
   elona_id = 404,
   related_skill = "elona.stat_will",
   element_id = nil,
   dice_x = function(p, l) return l/20+3 end,
   dice_y = function(p, l) return p/15+5 end,
   bonus = function(p, l) return p/10 end,
   element_power = nil,
   cost = 38,
   difficulty = 500,
   ball_cb = ball_cb_healing_rain
}

local function ball_cb_rain_of_sanity(self, x, y, tx, ty, source, target, element, params)
   if source:reaction_towards(target) >= 0 then
      local cb = Anim.heal(tx, ty, "base.heal_effect", "base.heal1", 5)
      Gui.start_draw_callback(cb)
      Gui.mes_visible("magic.rain_of_sanity", target.x, target.y, target)
      Effect.heal_insanity(target, params.power / 10)
      target:heal_effect("elona.insanity", 9999)
   end
end

make_ball {
   _id = "rain_of_sanity",
   elona_id = 404,
   type = "action",
   related_skill = "elona.stat_will",
   element_id = nil,
   dice_x = nil,
   dice_y = nil,
   bonus = nil,
   element_power = nil,
   cost = 38,
   difficulty = 500,
   ball_cb = ball_cb_rain_of_sanity
}

local function mes_if_can_see(target, mes, ...)
   if Chara.player():has_effect("elona.blindness") or not target:is_in_fov() then
      return
   end

   Gui.mes(mes, ...)
end

data:add {
   _id = "action_suicide_attack",
   _type = "base.skill",

   type = "action",
   effect_id = "elona.suicide_attack",
   related_skill = "elona.stat_constitution",
   cost = 20,
   range = 2,
   difficulty = 450,
   target_type = "nearby"
}
data:add {
   _id = "suicide_attack",
   _type = "elona_sys.magic",
   elona_id = 644,

   type = "action",
   params = {
      "source"
   },

   dice = function(self, params)
      local level = params.source:skill_level("elona.action_suicide_attack")
      return {
         x = 1 + level / 25,
         y = 15 + level / 5,
         bonus = 0
      }
   end,

   cast = function(self, params)
      local map = params.source:current_map()
      local original = params.source

      local chain_bomb = Queue:new()
      chain_bomb:push(params.source)

      local range = 2

      while chain_bomb:len() > 0 do
         local source = chain_bomb:pop()

         if Chara.is_alive(source) then
            if source == original then
               mes_if_can_see(source, "magic.explosion.begins", source)
            else
               mes_if_can_see(source, "magic.explosion.chain", source)
            end

            params.source = source -- to ensure self:dice(params) is correct
            local x = source.x
            local y = source.y

            local positions = ElonaPos.make_ball(x, y, range, map)

            local cb = Anim.ball(positions, nil, nil, x, y, map)
            Gui.start_draw_callback(cb)

            source:reset("is_about_to_explode", false)

            for _, pos in ipairs(positions) do
               local tx = pos[1]
               local ty = pos[2]

               local target = Chara.at(tx, ty)

               if target then
                  if x ~= tx or y ~= ty then
                     -- TODO riding
                     local dice = self:dice(params)
                     local damage = Rand.roll_dice(dice.x, dice.y, dice.bonus) * 100 / (75 + Pos.dist(tx, ty, x, y) * 25)

                     local success, damage = SkillCheck.handle_control_magic(source, target, damage)
                     if not success then
                        local tense = "enemy"
                        if not target:is_ally() then
                           tense = "ally"
                        end
                        if tense == "ally" then
                           Gui.mes_visible("magic.explosion.other", tx, ty, target)
                        else
                           Gui.mes_visible("magic.explosion.ally", tx, ty, target)
                        end

                        if target:calc("is_explodable") then
                           chain_bomb:push(target)
                        else
                           target:damage_hp(damage,
                                            source,
                                            {
                                               message_tense = tense,
                                               no_attack_text = true,
                                               is_third_person = true
                           })
                        end
                     end
                  end
               end
            end
         end

         source:damage_hp(99999, "elona.explosion")
      end

      return true
   end
}

-- heal


local function make_heal(opts)
   local full_id = "elona.spell_" .. opts._id

   data:add {
      _id = "spell_" .. opts._id,
      _type = "base.skill",

      type = "spell",
      effect_id = "elona." .. opts._id,
      related_skill = "elona.stat_will",
      cost = opts.cost,
      range = RANGE_BALL,
      difficulty = opts.difficulty,
      target_type = opts.target_type or "self"
   }

   data:add {
      _id = opts._id,
      _type = "elona_sys.magic",
      elona_id = opts.elona_id,

      type = "action",
      params = {
         "source",
         "target"
      },

      dice = function(self, params)
         local level = params.source:skill_level(full_id)
         return {
            x = (opts.dice_x and opts.dice_x(params.power, level)) or 0,
            y = (opts.dice_y and opts.dice_y(params.power, level)) or 0,
            bonus = (opts.dice_bonus and opts.dice_bonus(params.power, level)) or 0,
            element_power = (opts.dice_element_power and opts.dice_element_power(params.power, level)) or 0
         }
      end,

      cast = function(self, params)
         local target = params.target

         Gui.mes_visible(opts.message, target.x, target.y, target)

         local dice = self:dice(params)
         Effect.heal(target, dice.x, dice.y, dice.bonus)

         if params.curse_state == "blessed" then
            target:heal_effect("elona.sick", 5 + Rand.rnd(5))
         elseif Effect.is_cursed(params.curse_state) then
            make_sick(target, 3)
         end

         local cb = Anim.heal(target.x, target.y, "base.heal_effect", "base.heal1")
         Gui.start_draw_callback(cb)

         return true
      end
   }
end

make_heal {
   _id = "heal_light",
   message = "magic.healed.slightly",
   dice_x = function(p, l) return 1 + l / 30 end,
   dice_y = function(p, l) return p / 40 + 5 end,
   bonus = function(p, l) return p / 30 end,
   cost = 6,
   difficulty = 80
}

make_heal {
   _id = "heal_critical",
   message = "magic.healed.normal",
   dice_x = function(p, l) return 2 + l / 26 end,
   dice_y = function(p, l) return p / 25 + 5 end,
   bonus = function(p, l) return p / 15 end,
   cost = 15,
   difficulty = 350
}

make_heal {
   _id = "healing_touch",
   message = "magic.healed.normal",
   dice_x = function(p, l) return 2 + l / 22 end,
   dice_y = function(p, l) return p / 18 + 5 end,
   bonus = function(p, l) return p / 10 end,
   cost = 20,
   difficulty = 400,
   target_type = "nearby"
}

make_heal {
   _id = "cure_of_eris",
   message = "magic.healed.greatly",
   dice_x = function(p, l) return 3 + l / 15 end,
   dice_y = function(p, l) return p / 12 + 5 end,
   bonus = function(p, l) return p / 6 end,
   cost = 35,
   difficulty = 800
}

make_heal {
   _id = "cure_of_jure",
   message = "magic.healed.completely",
   dice_x = function(p, l) return 5 + l / 10 end,
   dice_y = function(p, l) return p / 7 + 5 end,
   bonus = function(p, l) return p / 2 end,
   cost = 80,
   difficulty = 1300
}

-- teleport

local function teleport_to(chara, x, y, check_cb, pos_cb, success_message, ...)
   local prevents_teleport = false -- TODO
   if prevents_teleport then
      if chara:is_in_fov() then
         Gui.mes("magic.teleport.prevented")
      end
      return true
   end

   if check_cb and not check_cb() then
      return true
   end

   if chara:is_in_fov() then
      Gui.play_sound("base.teleport1", chara.x, chara.y)
   end

   local map = chara:current_map()
   for attempt = 1, 200 do
      local next_x, next_y = pos_cb(x, y, attempt)
      next_x = math.floor(next_x)
      next_y = math.floor(next_y)

      if map:can_access(next_x, next_y) then
         if chara:is_in_fov() then
            if success_message then
               Gui.mes(success_message, ...)
            else
               Gui.mes("magic.teleport.disappears", chara)
            end
         end

         chara:remove_activity()
         chara:set_pos(next_x, next_y)
         if chara:is_player() then
            Gui.update_screen()
         end

         break
      end
   end

   return true
end

data:add {
   _id = "spell_teleport",
   _type = "base.skill",
   elona_id = 408,

   type = "spell",
   effect_id = "elona.teleport",
   related_skill = "elona.stat_magic",
   cost = 10,
   range = 0,
   difficulty = 400,
   target_type = "self",

   calc_mp_cost = mp_cost_constant
}

data:add {
   _id = "teleport",
   _type = "elona_sys.magic",
   elona_id = 408,

   params = {
      "source",
   },

   cast = function(self, params)
      local source = params.source
      local map = params.source:current_map()

      local pos = function(x, y, attempt)
         return Rand.rnd(map:width() - 2) + 1, Rand.rnd(map:height() - 2) + 1
      end

      return teleport_to(source, params.x, params.y, nil, pos, nil)
   end
}

data:add {
   _id = "spell_teleport_other",
   _type = "base.skill",
   elona_id = 409,

   type = "spell",
   effect_id = "elona.teleport_other",
   related_skill = "elona.stat_magic",
   cost = 10,
   range = 0,
   difficulty = 200,
   target_type = "direction",

   calc_mp_cost = mp_cost_constant
}

data:add {
   _id = "teleport_other",
   _type = "elona_sys.magic",
   elona_id = 409,

   params = {
      "source",
   },

   cast = function(self, params)
      local x = params.x
      local y = params.y
      local map = params.source:current_map()

      local target = Chara.at(x, y, map)

      if target == nil then
         Gui.mes("common.nothing_happens")
         return true, { obvious = false }
      end

      local pos = function(x, y, attempt)
         return Rand.rnd(map:width() - 2) + 1, Rand.rnd(map:height() - 2) + 1
      end

      return teleport_to(target, params.x, params.y, nil, pos, nil)
   end
}

data:add {
   _id = "spell_short_teleport",
   _type = "base.skill",
   elona_id = 410,

   type = "spell",
   effect_id = "elona.dimensional_move",
   related_skill = "elona.stat_magic",
   cost = 8,
   range = 0,
   difficulty = 120,
   target_type = "self",

   calc_mp_cost = mp_cost_constant
}

data:add {
   _id = "action_dimensional_move",
   _type = "base.skill",
   elona_id = 627,

   type = "action",
   effect_id = "elona.dimensional_move",
   related_skill = "elona.stat_will",
   cost = 15,
   range = 0,
   difficulty = 0,
   target_type = "self"
}

data:add {
   _id = "dimensional_move",
   _type = "elona_sys.magic",
   elona_id = 410,

   params = {
      "source",
   },

   cast = function(self, params)
      local source = params.source

      local pos = function(x, y, attempt)
         return source.x + (3 - attempt / 70 + Rand.rnd(5)) * (Rand.one_in(2) and -1 or 1),
                source.y + (3 - attempt / 70 + Rand.rnd(5)) * (Rand.one_in(2) and -1 or 1)
      end

      return teleport_to(source, params.x, params.y, nil, pos, nil)
   end
}

data:add {
   _id = "action_shadow_step",
   _type = "base.skill",
   elona_id = 619,

   type = "spell",
   effect_id = "elona.shadow_step",
   related_skill = "elona.stat_will",
   cost = 10,
   range = RANGE_BREATH,
   difficulty = 0,
   target_type = "other"
}

data:add {
   _id = "shadow_step",
   _type = "elona_sys.magic",
   elona_id = 619,

   params = {
      "source",
      "target",
   },

   cast = function(self, params)
      local source = params.source
      local target = params.target

      local pos = function(x, y, attempt)
         return x + Rand.rnd(attempt / 8 + 2) - Rand.rnd(attempt / 8 + 2),
         y + Rand.rnd(attempt / 8 + 2) - Rand.rnd(attempt / 8 + 2)
      end

      return teleport_to(source, target.x, target.y, nil, pos, "magic.teleport.shadow_step", source, target)
   end
}

data:add {
   _id = "action_draw_shadow",
   _type = "base.skill",
   elona_id = 620,

   type = "action",
   effect_id = "elona.draw_shadow",
   related_skill = "elona.stat_will",
   cost = 10,
   range = RANGE_BREATH,
   difficulty = 0,
   target_type = "other"
}

data:add {
   _id = "draw_shadow",
   _type = "elona_sys.magic",
   elona_id = 620,

   params = {
      "source",
      "target",
   },

   cast = function(self, params)
      local source = params.source
      local target = params.target

      local pos = function(x, y, attempt)
         return x + Rand.rnd(attempt / 8 + 2) - Rand.rnd(attempt / 8 + 2),
         y + Rand.rnd(attempt / 8 + 2) - Rand.rnd(attempt / 8 + 2)
      end

      return teleport_to(target, source.x, source.y, nil, pos, "magic.teleport.draw_shadow", target)
   end
}

data:add {
   _id = "action_suspicious_hand",
   _type = "base.skill",
   elona_id = 635,

   type = "action",
   effect_id = "elona.suspicious_hand",
   related_skill = "elona.stat_dexterity",
   cost = 10,
   range = RANGE_BREATH,
   difficulty = 0,
   target_type = "nearby"
}

data:add {
   _id = "suspicious_hand",
   _type = "elona_sys.magic",
   elona_id = 635,

   params = {
      "source",
      "target",
   },

   cast = function(self, params)
      local source = params.source
      local x = params.x
      local y = params.y
      local map = params.source:current_map()

      local target = Chara.at(x, y, map)

      if target == nil then
         Gui.mes("common.nothing_happens")
         return true, { obvious = false }
      end

      if source == target then
         Gui.mes_visible("magic.teleport.prevented", target.x, target.y)
         return false
      end

      local amount = Rand.rnd(target.gold / 10 + 1)
      if Rand.rnd(target:skill_level("elona.stat_perception")) > Rand.rnd(source:skill_level("elona.stat_dexterity") * 4)
         or target:calc("is_resistant_to_stealing")
      then
         Gui.mes("magic.teleport.suspicious_hand.prevented", target)
         amount = 0
      end

      if amount > 0 then
         Gui.play_sound("base.paygold1")
         target.gold = target.gold - amount
         Gui.mes("magic.teleport.suspicious_hand.succeeded", source, target, amount)
         source.gold = source.gold + amount
         -- TODO riding
      end

      local pos = function(x, y, attempt)
         return Rand.rnd(map:width() - 2) + 1, Rand.rnd(map:height() - 2) + 1
      end

      return teleport_to(source, params.x, params.y, nil, pos, "magic.teleport.suspicious_hand.after")
   end
}

-- hand

-- summon

local function make_breath(element_id, elona_id, dice_x, dice_y, bonus, cost)
   local id
   if element_id then
      id = element_id .. "_breath"
      element_id = "elona." .. element_id
   else
      id = "power_breath"
   end

   data:add {
      _id = "action_" .. id,
      _type = "base.skill",

      type = "action",
      effect_id = "elona." .. id,
      related_skill = "elona.stat_constitution",
      cost = cost,
      range = RANGE_BREATH,
      difficulty = 0,
      target_type = "target_or_location"
   }

   data:add {
      _id = id,
      _type = "elona_sys.magic",
      elona_id = elona_id,

      type = "action",
      params = {
         "source"
      },

      dice = function(self, params)
         local level = params.source:skill_level("elona.action_" .. id)
         return {
            x = 1 + level / dice_x,
            y = dice_y,
            bonus = level / bonus
         }
      end,

      cast = function(self, params)
         local map = params.source:current_map()
         local source = params.source
         local sx = params.source.x
         local sy = params.source.y
         if not map:has_los(sx, sy, params.x, params.y) then
            return false
         end

         local element, color, sound
         if element_id then
            element = data["base.element"]:ensure(element_id)
            color = element.color
            sound = element.sound
         end

         if map:is_in_fov(sx, sy) then
            local breath_name
            if element_id then
               breath_name = I18N.get("magic.breath.named", "element." .. element_id .. ".name")
            else
               breath_name = I18N.get("magic.breath.named", "magic.breath.no_element")
            end
            Gui.mes_visible("magic.breath.bellows", sx, sy, params.source, breath_name)

            local positions = ElonaPos.make_breath(sx, sy, params.x, params.y, params.range, map)

            local cb = Anim.breath(positions, color, sound, sx, sy, params.x, params.y, map)
            Gui.start_draw_callback(cb)

            for _, pos in ipairs(positions) do
               local tx = pos[1]
               local ty = pos[2]

               if map:has_los(sx, sy, tx, ty) and (sx ~= tx or sy ~= ty) then
                  -- TODO riding
                  if element and element.on_damage_tile then
                     element:on_damage_tile(tx, ty, source)
                  end
                  local chara = Chara.at(tx, ty, map)
                  if chara then
                     local dice = self:dice(params)
                     local damage = Rand.roll_dice(dice.x, dice.y, dice.bonus)

                     local tense = "enemy"
                     if not params.source:is_ally() then
                        tense = "ally"
                     end
                     if tense == "ally" then
                        Gui.mes_visible("magic.breath.other", tx, ty, chara)
                     else
                        Gui.mes_visible("magic.breath.ally", tx, ty, chara)
                     end
                     chara:damage_hp(damage,
                                     params.source,
                                     {
                                        element = element_id,
                                        element_power = params.element_power,
                                        message_tense = tense,
                                        no_attack_text = true,
                                        is_third_person = true
                     })
                  end
               end
            end
         end
         return true
      end
   }
end

make_breath("fire",      602, 15, 7, 8,  12)
make_breath("cold",      603, 15, 7, 8,  10)
make_breath("lightning", 604, 15, 7, 8,  10)
make_breath("chaos",     605, 15, 7, 8,  10)
make_breath("poison",    606, 15, 7, 8,  10)
make_breath("nether",    607, 15, 7, 8,  10)
make_breath("sound",     608, 15, 7, 8,  10)
make_breath("darkness",  609, 15, 7, 8,  10)
make_breath("mind",      610, 15, 7, 8,  10)
make_breath("nerve",     611, 15, 7, 8,  10)
make_breath(nil,         612, 20, 6, 15, 10)