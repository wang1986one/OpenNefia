local Map = require("api.Map")
local IDrawLayer = require("api.gui.IDrawLayer")
local Draw = require("api.Draw")
local tile_batch = require("internal.draw.tile_batch")

-- Draws the "overhang" parts of walls.
local tile_overhang_layer = class.class("tile_overhang_layer", IDrawLayer)

function tile_overhang_layer:init(width, height, coords)
   local coords = Draw.get_coords()
   local tile_atlas, chara_atlas, item_atlas = require("internal.global.atlases").get()

   self.tile_batch = tile_batch:new(width, height, tile_atlas, coords)
end

function tile_overhang_layer:relayout()
end

function tile_overhang_layer:reset()
   self.batch_inds = {}
end

local function calc_map_shadow(map, hour)
   if not map.is_outdoors then
      return 0
   end

   local shadow = 0

   if hour >= 24 or (hour >= 0 and hour < 4) then
      shadow = 110
   elseif hour >= 4 and hour < 10 then
      shadow = math.max(10, 70 - (hour - 3) * 10)
   elseif hour >= 10 and hour < 12 then
      shadow = 10
   elseif hour >= 12 and hour < 17 then
      shadow = 1
   elseif hour >= 17 and hour < 21 then
      shadow = (hour - 17) * 20
   elseif hour >= 21 and hour < 24 then
      shadow = 80 + (hour - 21) * 10
   end

   -- TODO weather, noyel

   return shadow
end

function tile_overhang_layer:update(dt, screen_updated)
   if not screen_updated then return end

   self.tile_batch.updated = true

   local map = Map.current()
   assert(map ~= nil)

   if map.tiles_dirty then
      for i, t in ipairs(map.tiles) do
         local x = (i-1) % map.width
         local y = math.floor((i-1) / map.width)
         local id = t._id

         if t.wall then
            local one_tile_down = map.tiles[(y+1)*map.width+x+1]
            if one_tile_down ~= nil and not one_tile_down.wall then
               id = t.wall
            end
         end

         self.tile_batch:update_tile(x, y, id)
      end
      map.tiles_dirty = false
   end

   -- TODO: maybe have this field accessable somewhere better?
   local field = require("game.field")
   local date = field.data.date

   self.tile_batch.shadow = calc_map_shadow(map, date.hour)
end

function tile_overhang_layer:draw(draw_x, draw_y)
   self.tile_batch:draw(draw_x, draw_y)
end

return tile_overhang_layer