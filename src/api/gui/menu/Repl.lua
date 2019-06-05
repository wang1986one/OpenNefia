local Draw = require("api.Draw")
local Ui = require("api.Ui")

local IUiLayer = require("api.gui.IUiLayer")
local IInput = require("api.gui.IInput")
local InputHandler = require("api.gui.InputHandler")
local UiWindow = require("api.gui.UiWindow")
local UiList = require("api.gui.UiList")
local TextHandler = require("api.gui.TextHandler")

local Repl = class("Repl", IUiLayer)

Repl:delegate("input", IInput)

function Repl:init(env)
   self.text = ""
   self.caret = "> "
   self.env = env or {}
   self.result = ""

   self.input = InputHandler:new(TextHandler:new())
   self.input:bind_keys {
      text_entered = function(t)
         self.text = self.text .. t
      end,
      backspace = function()
         self.text = utf8.pop(self.text)
      end,
      text_submitted = function()
         self:submit()
         Draw.redraw_screen()
         self.input:halt_input()
      end,
      text_canceled = function() self.finished = true end,
   }
   self.input:halt_input()
end

function Repl:relayout(x, y, width, height)
   self.x = 0
   self.y = 0
   self.width = Draw.get_width()
   self.height = Draw.get_height() / 3
   self.color = {17, 17, 65, 192}
   self.font_size = 15
end

function Repl:submit()
   local text = self.text
   self.text = ""

   local chunk, err = loadstring(text)

   if chunk == nil then
      chunk, err = loadstring("return " .. text)

      if chunk == nil then
         self.result = err
         return
      end
   end
   -- setfenv(chunk, self.env)
   local success, result = pcall(chunk)
   self.result = tostring(result)
end

function Repl:draw()
   Draw.filled_rect(self.x, self.y, self.width, self.height, self.color)

   Draw.set_font(self.font_size)
   Draw.set_color(255, 255, 255)
   Draw.text(self.caret, self.x + 5, self.y + 5)
   Draw.text(self.text, self.x + 5 + Draw.text_width(self.caret), self.y + 5)
   Draw.text(self.result, self.x + 5, self.y + 5 + Draw.text_height())
end

function Repl:update(dt)
   if self.finished then
      return true
   end
end

return Repl
