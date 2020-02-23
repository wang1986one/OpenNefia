local Mx = require("mod.tools.api.Mx")
local Gui = require("api.Gui")
Gui.bind_keys {
   ["tools.m_x"] = function()
      Mx.start()
   end
}

local PicViewer = require("mod.tools.api.PicViewer")

local function cands()
   local keys = table.keys(data["base.theme"]["elona_sys.default"].assets)
   return Mx.completing_read(keys)
end
Mx.make_interactive("pic_viewer_start", PicViewer, "start", {cands})

local Input = require("api.Input")
Mx.make_interactive("input_reload_keybinds", Input, "reload_keybinds")

local Tools = require("mod.tools.api.Tools")
Mx.make_interactive("goto_down_stairs", Tools, "goto_down_stairs")
Mx.make_interactive("goto_up_stairs", Tools, "goto_up_stairs")
Mx.make_interactive("goto_map", Tools, "goto_map",
                    {
                       { type="elona_sys.map_template"}
                    })

local Chara = require("api.Chara")
Mx.make_interactive("chara_create", Chara, "create",
                    {
                       { type="base.chara" },
                       function() return Chara.player().x end,
                       function() return Chara.player().y end,
                    }
)

local Item = require("api.Item")
Mx.make_interactive("item_create", Item, "create",
                    {
                       { type="base.item" },
                       function() return Chara.player().x end,
                       function() return Chara.player().y end,
                       function()
                          return {
                             amount = Mx.read_type("number", { max=1000, initial_amount=1 })
                          }
                       end
                    })
