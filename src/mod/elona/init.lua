require("mod.elona.init.god")

require("mod.elona.data")

require("mod.elona.events")

local Gui = require("api.Gui")
local ElonaCommand = require("mod.elona.api.ElonaCommand")

-- "none", "could_not_sell", "all"
config["elona.hide_shop_results"] = "none"

Gui.bind_keys {
   quick_inv = function(_, me)
      return ElonaCommand.quick_inv(me)
   end,
   inventory = function(_, me)
      return ElonaCommand.inventory(me)
   end,
   bash = function(_, me)
      return ElonaCommand.bash(me)
   end,
   eat = function(_, me)
      return ElonaCommand.eat(me)
   end,
   fire = function(_, me)
      return ElonaCommand.fire(me)
   end,
   dig = function(_, me)
      return ElonaCommand.dig(me)
   end,
   read = function(_, me)
      return ElonaCommand.read(me)
   end,
   drink = function(_, me)
      return ElonaCommand.drink(me)
   end,
   zap = function(_, me)
      return ElonaCommand.zap(me)
   end,
   use = function(_, me)
      return ElonaCommand.use(me)
   end,
   dip = function(_, me)
      return ElonaCommand.dip(me)
   end,
   throw = function(_, me)
      return ElonaCommand.throw(me)
   end,
   rest = function(_, me)
      return ElonaCommand.rest(me)
   end,
   ammo = function(_, me)
      return ElonaCommand.ammo(me)
   end,
}
