local EquipSlots = require("api.EquipSlots")
local IItemEnchantments = require("api.item.IItemEnchantments")
local IMapObject = require("api.IMapObject")
local IObject = require("api.IObject")
local IModdable = require("api.IModdable")
local IEventEmitter = require("api.IEventEmitter")
local IStackableObject = require("api.IStackableObject")
local ILocalizable = require("api.ILocalizable")
local I18N = require("api.I18N")
local Log = require("api.Log")
local Gui = require("api.Gui")
local data = require("internal.data")
local Enum = require("api.Enum")

local IItem = class.interface("IItem",
                         {},
                         {IStackableObject, IModdable, IItemEnchantments, IEventEmitter, ILocalizable})

function IItem:pre_build()
   IModdable.init(self)
   IMapObject.init(self)
   IEventEmitter.init(self)
   IItemEnchantments.init(self)

   local fallbacks = data.fallbacks["base.item"]
   self:mod_base_with(table.deepcopy(fallbacks), "merge")
end

function IItem:normal_build()
   self.location = nil

   self.name = self._id

   self.image = self.proto.image
end

function IItem:build(params)
   params = params or {}
   self.name = I18N.get("item.info." .. self._id .. ".name")

   -- TODO remove params
   self:emit("base.on_build_item", params)

   self:refresh()
end

function IItem:instantiate()
   IObject.instantiate(self)
   self:emit("base.on_item_instantiated")
end

local Itemname = nil
function IItem:build_name(amount, no_article)
   Itemname = Itemname or require("mod.elona.api.Itemname")
   return Itemname.build_name(self, amount, no_article)
end

local function is_melee_weapon(item)
   return item:is_equipped()
      and not item:is_equipped_at("elona.ranged")
      and not item:is_equipped_at("elona.ammo")
      and item:calc("dice_x") > 0
end

local function is_ranged_weapon(item)
   return item:is_equipped_at("elona.ranged")
end

local function is_ammo(item)
   return item:is_equipped_at("elona.ammo")
end

function IItem:refresh()
   IModdable.on_refresh(self)
   IMapObject.on_refresh(self)
   IItemEnchantments.on_refresh(self)

   local material_id = self:calc("material")
   if material_id then
      local material_data = data["elona.item_material"]:ensure(material_id)
      if material_data.on_refresh then
         material_data.on_refresh(self)
      end
   end

   self:mod("is_melee_weapon", is_melee_weapon(self))
   self:mod("is_ranged_weapon", is_ranged_weapon(self))
   self:mod("is_ammo", is_ammo(self))
   self:mod("is_armor", self:calc("dice_x") == 0)

   self:emit("base.on_item_refresh")
end

function IItem:on_refresh()
end

--- @treturn[opt] IChara
function IItem:get_owning_chara()
   local IChara = require("api.chara.IChara")

   if class.is_an(IChara, self.location) then
      if self.location:has_item(self) then
         return self.location
      end
   elseif class.is_an(EquipSlots, self.location) then
      -- HACK
      return self.location.owner
   end

   return nil
end

local Item = nil

function IItem:produce_memory()
   local shadow_angle
   local stack_height = 8
   local is_tall = false
   local x_offset = self:calc("x_offset")
   local y_offset = self:calc("y_offset")
   local image = data["base.chip"][self.image or self.proto.image]
   if image then
      shadow_angle = image.shadow
      stack_height = image.stack_height or 8
      y_offset = y_offset or image.y_offset
   end

   Item = Item or require("api.Item")

   return {
      uid = self.uid,
      show = Item.is_alive(self),
      image = (self.image or ""),
      color = self:calc("color"),
      x_offset = x_offset,
      y_offset = y_offset,
      shadow_type = "drop_shadow",
      shadow = shadow_angle,
      stack_height = stack_height
   }
end

function IItem:produce_locale_data()
   return {
      name = self:build_name(),
      basename = self:calc("name"),
      amount = self.amount,
      is_visible = self:is_in_fov(),
   }
end

--- @treturn bool
function IItem:is_blessed()
   return self:calc("curse_state") == "blessed"
end

--- @treturn bool
function IItem:is_cursed()
   local curse_state = self:calc("curse_state")
   return curse_state == "cursed" or curse_state == "doomed"
end

--- @treturn[opt] InstancedMap
--- @overrides IMapObject.current_map
function IItem:current_map()
   -- BUG: Needs to be generalized to allow nesting.
   local chara = self:get_owning_chara()
   if chara and chara.state == "alive" then
      return chara:current_map()
   end

   return IMapObject.current_map(self)
end

--- @tparam id:base.body_part body_part_type
--- @treturn bool
function IItem:can_equip_at(body_part_type)
   local equip_slots = self:calc("equip_slots") or {}
   if #equip_slots == 0 then
      return nil
   end

   local can_equip = table.set(equip_slots)

   return can_equip[body_part_type] == true
end

--- @treturn bool
function IItem:is_equipped()
   return class.is_an(EquipSlots, self.location)
end

--- @tparam id:base.body_part body_part_type
--- @treturn bool
function IItem:slot_equipped_in()
   if not self:is_equipped() then
      return nil
   end

   local slot = self.location:equip_slot_of(self)
   return slot and slot.type
end

-- TODO remove
--- @tparam id:base.body_part body_part_type
--- @treturn bool
function IItem:is_equipped_at(body_part_type)
   return self:slot_equipped_in() == body_part_type
end

function IItem:remove_activity(no_message)
   if not self.chara_using then
      return
   end

   if not no_message then
      Gui.mes("activity.cancel.item", self.chara_using)
   end

   self.chara_using:remove_activity()
   self.chara_using = nil
end

function IItem:can_stack_with(other)
   -- TODO: this gets super complicated when adding new fields. There
   -- should be a way to specify a field will not have any effect on
   -- the stacking behavior between two objects.
   if not IStackableObject.can_stack_with(self, other) then
      return false
   end

   local ignored_fields = table.set {
      "uid",
      "amount",
      "temp",

      -- TODO: Compare event tables by event name, since those are
      -- uniquely idenfying.
      "_events",
      "global_events",
   }

   local ok, err = IEventEmitter.compare_events(self, other)
   if not ok then
      return false, "events don't match"
   end

   for field, my_val in pairs(self) do
      if not ignored_fields[field] then
         local their_val = other[field]

         -- TODO: is_class, is_object
         local do_deepcompare = type(my_val) == "table"
            and type(their_val) == "table"
            and my_val.__class == nil
            and my_val.uid == nil

         if do_deepcompare then
            if not #my_val == #their_val then
               return false, field
            end
            Log.trace("Stack: deepcomparing %s", field)
            if not table.deepcompare(my_val, their_val) then
               return false, field
            end
         else
            if my_val ~= their_val then
               return false, field
            end
         end
      end
   end

   return true
end

function IItem:calc_effective_range(dist)
   dist = math.max(math.floor(dist), 0)
   local result
   local effective_range = self:calc("effective_range")
   if type(effective_range) == "function" then
      result = effective_range(self, dist)
      assert(type(result) == "number", "effective_range must return a number")
   elseif type(effective_range) == "table" then
      result = effective_range[dist]
      if not result then
         -- vanilla compat
         result = effective_range[math.min(dist, 9)]
      end
   elseif type(effective_range) == "number" then
      result = effective_range
   end
   return result or 100
end

function IItem:calc_ui_color()
   local color = self:calc("ui_color")
   if color then return color end

   if self:calc("is_no_drop") then
        return {120, 80, 0}
   end

   if self:calc("identify_state") == Enum.IdentifyState.Full then
      local curse_state = self:calc("curse_state")
      if     curse_state == "doomed"  then return {100, 10, 100}
      elseif curse_state == "cursed"  then return {150, 10, 10}
      elseif curse_state == "none"    then return {10, 40, 120}
      elseif curse_state == "blessed" then return {10, 110, 30}
      end
   end

    return {0, 0, 0}
end

function IItem:remove(amount)
   -- >>>>>>>> elona122/shade2/item_func.hsp:191 #deffunc removeItem int id,int num ..
   if amount == nil then
      amount = self.amount
   end
   self.amount = math.clamp(self.amount - amount, 0, self.amount)

   self:refresh_cell_on_map()

   local chara = self:get_owning_chara()
   if chara then
      chara:refresh_weight()
   end

   if self.amount == 0 then
      self:remove_ownership()
   end
   -- <<<<<<<< elona122/shade2/item_func.hsp:202 	return ..
end

function IItem:has_category(cat)
   if type(cat) == "table" then
      for _, t in ipairs(cat) do
         assert(type(t) == "string")
         if self:has_type(t) then
            return true
         end
      end
   else
      for _, v in ipairs(self.categories) do
         if v == cat then
            return true
         end
      end
   end

   return false
end

function IItem:major_categories()
   local categories = {}
   for _, category in ipairs(self.categories) do
      local item_type = data["base.item_type"]:ensure(category)
      if item_type.is_major then
         categories[#categories+1] = category
      end
   end
   return categories
end

return IItem
