local mod = require("internal.mod")
local internal = require("internal")
local i18n = require("internal.i18n")
local data = require("internal.data")
local field = require("game.field")
local stopwatch = require("api.Stopwatch")
local UiTheme = require("api.gui.UiTheme")
local Event = require("api.Event")
local Log = require("api.Log")

local startup = {}

function startup.run(mods)
   math.randomseed(internal.get_timestamp())

   require("internal.data.base")

   mod.load_mods(mods)
   data:run_all_edits()

   -- data is finalized at this point.

   startup.load_batches()

   i18n.switch_language("en")

   local default_theme = "elona_sys.default"
   UiTheme.add_theme(default_theme)

   field:setup_repl()

   Event.trigger("base.on_game_startup")
end

local tile_batch = require("internal.draw.tile_batch")
local sparse_batch = require("internal.draw.sparse_batch")
local atlas = require("internal.draw.atlas")
local batches = {}

local function get_map_tiles()
   return data["base.map_tile"]:iter()
end

local mkpred = function(group)
   return function(i) return i.group == group end
end

local function get_chara_tiles()
   return data["base.chip"]:iter():filter(mkpred("chara"))
end

local function get_item_tiles()
   return data["base.chip"]:iter():filter(mkpred("item"))
end

local function get_feat_tiles()
   return data["base.chip"]:iter():filter(mkpred("feat"))
end

local tile_size = 48
local atlas_size = 96

function startup.load_batches()
   Log.info("Loading tile batches.")

   local coords = require("internal.draw.coords.tiled_coords"):new()
   internal.draw.set_coords(coords)

   local sw = stopwatch:new()
   sw:measure()

   local tile_atlas = atlas:new(atlas_size, atlas_size, tile_size, tile_size)
   tile_atlas:load(get_map_tiles(), coords)

   sw:p("load_batches.map")

   local chara_atlas = atlas:new(atlas_size, atlas_size, tile_size, tile_size)
   chara_atlas:load(get_chara_tiles())

   sw:p("load_batches.chara")

   local item_atlas = atlas:new(atlas_size, atlas_size, tile_size, tile_size)
   item_atlas:load(get_item_tiles())

   sw:p("load_batches.item")

   local feat_atlas = atlas:new(atlas_size, atlas_size, tile_size, tile_size)
   feat_atlas:load(get_feat_tiles())

   sw:p("load_batches.feat")

   local atlases = require("internal.global.atlases")
   atlases.set(tile_atlas, chara_atlas, item_atlas, feat_atlas)
end

return startup
