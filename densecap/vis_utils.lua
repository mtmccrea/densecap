require 'image'

local vis_utils = {}

-- Some nice colors for drawing colors
-- vis_utils.WAD_COLORS = {
--   {173, 35,  25 }, -- Red
--   {42,  75,  215}, -- Blue
--   {87,  87,  87 }, -- Dark Gray
--   {29,  105, 20 }, -- Green
--   {129, 74,  25 }, -- Brown
--   -- {160, 160, 160}, -- Light Gray
--   {129, 197, 122}, -- Light green
--   {157, 175, 255}, -- Light blue
--   {41,  208, 208}, -- Cyan
--   {255, 146, 51 }, -- Orange
--   {255, 216, 73 }, -- Yellow
--   {233, 222, 187}, -- Tan
--   {255, 205, 243}, -- Pink
--   {1,   1,   1  }, -- Black
-- }

-- Some nice colors for drawing colors
-- above * 0.75 to make txt more visible
    -- for quick scaling of color values in supercollider:
    -- (
    -- [
    --   [173, 35,  25 ],
    --   [42,  75,  215],
    --   [87,  87,  87 ],
    --   [29,  105, 20 ],
    --   [129, 74,  25 ],
    --   [160, 160, 160],
    --   [129, 197, 122],
    --   [157, 175, 255],
    --   [41,  208, 208],
    --   [255, 146, 51 ],
    --   [255, 216, 73 ],
    --   [233, 222, 187],
    --   [255, 205, 243],
    --   [1,   1,   1  ],
    -- ] * 0.75
    -- ).do({|me|
    -- 	postf("{%, %, %},\n", *me.round.asInteger)
    -- })
vis_utils.WAD_COLORS = {
    {130, 26, 19},
    {32, 56, 161},
    {65, 65, 65},
    {22, 79, 15},
    {97, 56, 19},
    {120, 120, 120},
    {97, 148, 92},
    {118, 131, 191},
    {31, 156, 156},
    {191, 110, 38},
    {191, 162, 55},
    {175, 167, 140},
    {191, 154, 182},
    {1, 1, 1},
}

local function clamp(x, low, high)
  if x < low then
    return low
  elseif x > high then
    return high
  else
    return x
  end
end


--[[
Inputs:
- img: 3 x H x W Tensor of pixel data
- boxes: N x 4 Tensor of box coordinates in (x, y, w, h) format
- captions: Array of N strings

Returns:
- img_disp: Copy of img with boxes and captions drawn in
--]]
function vis_utils.densecap_draw(img, boxes, captions, options)
  local img = img:clone()

  local H, W = img:size(2), img:size(3)
  local N = boxes:size(1)

  options = options or {}
  local text_size = options.text_size or 1
  local box_width = options.box_width or 2

  local text_img = img:clone():zero()
  img:zero() -- to output just a black background to fade with source video

  -- --https://github.com/torch/image/blob/master/doc/drawing.md
  -- for i = 1, N do
  --   local rgb = vis_utils.WAD_COLORS[i % #vis_utils.WAD_COLORS + 1]
  --   local rgb_255 = {255 * rgb[1], 255 * rgb[2], 255 * rgb[3]}
  --   vis_utils.draw_box(img, boxes[i], rgb, box_width)
  --
  --   local x = boxes[{i, 1}] + box_width + 1
  --   local y = boxes[{i, 2}] + box_width + 1
  --   --settings for the colored box underlying the text
  --   local text_opt_bg = {
  --     inplace=true,
  --     size=text_size,
  --     color={rgb[1], rgb[2], rgb[3]},
  --     bg={rgb[1], rgb[2], rgb[3]},
  --   }
  --   --settings for the colored text
  --   local text_opt = {
  --       inplace=true,
  --       size=text_size,
  --       color=rgb_255,
  --   }
  --
  --   local ok, err = pcall(function()
  --     image.drawText(img, captions[i], x, y, text_opt_bg)
  --   end)
  --   if not ok then
  --     print('drawText out of bounds 1: ', x, y, W, H)
  --   end
  --   local ok, err = pcall(function()
  --     image.drawText(text_img, captions[i], x, y, text_opt)
  --   end)
  --   if not ok then
  --     print('drawText out of bounds 2: ', x, y, W, H)
  --   end
  -- end
  -- -- scale pixel values to 0>1
  -- text_img:div(255)
  -- -- force txt to white
  -- text_img[torch.ne(text_img, 0)] = 1
  -- -- zero out pixels of target image where text image contains info/colors
  -- -- this prepares the addition that follows so multiple texts don't continually add up
  -- img[torch.ne(text_img, 0)] = 0
  -- -- add the text image to the target image
  -- img:add(text_img)

  -- this loop for white boxes only
  -- comment out everything above through the loop below the link
  for i = 1, N do
    vis_utils.draw_box(img, boxes[i], {255, 255, 255}, box_width)
  end

  return img
end


function vis_utils.draw_box(img, box, color, lw)
  lw = lw or 1
  local x, y, w, h = unpack(box:totable())
  local H, W = img:size(2), img:size(3)

  local top_x1 = clamp(x - lw, 1, W)
  local top_x2 = clamp(x + w + lw, 1, W)
  local top_y1 = clamp(y - lw, 1, H)
  local top_y2 = clamp(y + lw, 1, H)

  local bottom_y1 = clamp(y + h - lw, 1, H)
  local bottom_y2 = clamp(y + h + lw, 1, H)

  local left_x1 = clamp(x - lw, 1, W)
  local left_x2 = clamp(x + lw, 1, W)
  local left_y1 = clamp(y - lw, 1, H)
  local left_y2 = clamp(y + h + lw, 1, H)

  local right_x1 = clamp(x + w - lw, 1, W)
  local right_x2 = clamp(x + w + lw, 1, W)


  for c = 1, 3 do
    local cc = color[c] / 255
    img[{c, {top_y1, top_y2}, {top_x1, top_x2}}] = cc
    img[{c, {bottom_y1, bottom_y2}, {top_x1, top_x2}}] = cc
    img[{c, {left_y1, left_y2}, {left_x1, left_x2}}] = cc
    img[{c, {left_y1, left_y2}, {right_x1, right_x2}}] = cc
  end
end


return vis_utils
