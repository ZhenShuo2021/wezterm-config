local wezterm = require('wezterm')

-- Steal from https://github.com/AM-I-Human/wezterm-config/blob/master/events/tab-title.lua
-- Inspired by https://github.com/wez/wezterm/discussions/628#discussioncomment-1874614

local nf = wezterm.nerdfonts

local GLYPH_SEMI_CIRCLE_LEFT = nf.ple_left_half_circle_thick --[[ '' ]]
local GLYPH_SEMI_CIRCLE_RIGHT = nf.ple_right_half_circle_thick --[[ '' ]]
local GLYPH_CIRCLE = nf.fa_circle --[[ '' ]]
local GLYPH_ADMIN = nf.md_shield_half_full --[[ '󰞀' ]]

local M = {}

local __cells__ = {} -- wezterm FormatItems (ref: https://wezfurlong.org/wezterm/config/lua/wezterm/format.html)

-- Load colors from external file
local colorscheme = require('colors.custom')

local colors = {
   default   = { bg = '#45475A', fg = '#1C1B19' },
   is_active = { bg = '#74c7ec', fg = '#1C1B19' },
   hover     = { bg = '#74c7ec', fg = '#1C1B19' },
}

local _set_process_name = function(s)
   local a = string.gsub(s, '(.*[/\\])(.*)', '%2')
   return a:gsub('%.exe$', '')
end

local _set_title = function(process_name, base_title, max_width, inset)
   local title
   inset = inset or 11

   if process_name:len() > 0 then
      title = process_name
   else
      title = base_title
   end

   if title:len() > max_width - inset then
      -- 當文字超出長度，截斷並添加省略號
      title = title:sub(1, max_width - inset - 1) .. '…'
   else
      -- 計算左右填充空格以實現居中
      local total_padding = max_width - title:len() - inset
      local left_padding = math.floor(total_padding / 2)
      local right_padding = total_padding - left_padding
      title = string.rep(' ', left_padding) .. title .. string.rep(' ', right_padding)
   end
   
   return title
end

local _check_if_admin = function(p)
   if p:match('^Administrator: ') then
      return true
   end
   return false
end

---@param fg string
---@param bg string
---@param attribute table
---@param text string
local _push = function(bg, fg, attribute, text)
   table.insert(__cells__, { Background = { Color = bg } })
   table.insert(__cells__, { Foreground = { Color = fg } })
   table.insert(__cells__, { Attribute = attribute })
   table.insert(__cells__, { Text = text })
end

M.setup = function()
   wezterm.on('format-tab-title', function(tab, _tabs, _panes, _config, hover, max_width)
      __cells__ = {}

      local bg
      local fg
      local process_name = _set_process_name(tab.active_pane.foreground_process_name)
      local is_admin = _check_if_admin(tab.active_pane.title)
      local title = _set_title(process_name, tab.active_pane.title, max_width, (is_admin and 8))

      if tab.is_active then
         bg = colors.is_active.bg
         fg = colors.is_active.fg
      elseif hover then
         bg = colors.hover.bg
         fg = colors.hover.fg
      else
         bg = colors.default.bg
         fg = colors.default.fg
      end

      local has_unseen_output = false
      for _, pane in ipairs(tab.panes) do
         if pane.has_unseen_output then
            has_unseen_output = true
            break
         end
      end

      -- Left semi-circle
      _push('rgba(0, 0, 0, 0.4)', bg, { Intensity = 'Bold' }, GLYPH_SEMI_CIRCLE_LEFT)

      -- Admin Icon
      if is_admin then
         _push(bg, fg, { Intensity = 'Bold' }, ' ' .. GLYPH_ADMIN)
      end

      -- Title
      _push(bg, fg, { Intensity = 'Bold' }, ' ' .. title)

      -- Unseen output alert
      if has_unseen_output then
         _push(bg, '#FFA066', { Intensity = 'Bold' }, ' ' .. GLYPH_CIRCLE)
      end

      -- Right padding
      _push(bg, fg, { Intensity = 'Bold' }, ' ')

      -- Right semi-circle
      _push('rgba(0, 0, 0, 0.4)', bg, { Intensity = 'Bold' }, GLYPH_SEMI_CIRCLE_RIGHT)

      return __cells__
   end)
end

return M
