local M = {}

local ns = vim.api.nvim_create_namespace("rainbow-tags.nvim")

local default_groups = {
  "RainbowTagsRed",
  "RainbowTagsCyan",
  "RainbowTagsYellow",
  "RainbowTagsGreen",
  "RainbowTagsOrange",
  "RainbowTagsViolet",
  "RainbowTagsBlue",
}

local default_links = {
  RainbowTagsRed = "RainbowDelimiterRed",
  RainbowTagsCyan = "RainbowDelimiterCyan",
  RainbowTagsYellow = "RainbowDelimiterYellow",
  RainbowTagsGreen = "RainbowDelimiterGreen",
  RainbowTagsOrange = "RainbowDelimiterOrange",
  RainbowTagsViolet = "RainbowDelimiterViolet",
  RainbowTagsBlue = "RainbowDelimiterBlue",
}

local delimiter_groups = {
  "RainbowDelimiterRed",
  "RainbowDelimiterCyan",
  "RainbowDelimiterYellow",
  "RainbowDelimiterGreen",
  "RainbowDelimiterOrange",
  "RainbowDelimiterViolet",
  "RainbowDelimiterBlue",
}

local default_config = {
  enabled = true,
  filetypes = {
    "typescriptreact",
    "javascriptreact",
    "tsx",
  },
  lang = "tsx",
  highlight_groups = default_groups,
  create_default_highlights = true,
  include_intrinsic = true,
  strategy = "name",
}

local config = vim.deepcopy(default_config)
local provider_attached = false
local enabled_buffers = {}
local query_cache = {}

local tsx_query = [[
  (jsx_opening_element
    name: (_) @tag.name)

  (jsx_closing_element
    name: (_) @tag.name)

  (jsx_self_closing_element
    name: (_) @tag.name)
]]

local default_highlights = {
  RainbowDelimiterRed = { fg = "#e06c75" },
  RainbowDelimiterCyan = { fg = "#56b6c2" },
  RainbowDelimiterYellow = { fg = "#e5c07b" },
  RainbowDelimiterGreen = { fg = "#98c379" },
  RainbowDelimiterOrange = { fg = "#d19a66" },
  RainbowDelimiterViolet = { fg = "#c678dd" },
  RainbowDelimiterBlue = { fg = "#61afef" },
}

local function merge(user_config)
  config = vim.tbl_deep_extend("force", vim.deepcopy(default_config), user_config or {})
end

local function create_default_highlights()
  if not config.create_default_highlights then
    return
  end

  for group, link in pairs(default_links) do
    vim.api.nvim_set_hl(0, group, { link = link, default = true })
  end

  for _, group in ipairs(delimiter_groups) do
    local existing = vim.api.nvim_get_hl(0, { name = group, link = false })
    if vim.tbl_isempty(existing) then
      vim.api.nvim_set_hl(0, group, default_highlights[group])
    end
  end
end

local function is_supported_filetype(bufnr)
  local ft = vim.bo[bufnr].filetype
  return vim.tbl_contains(config.filetypes, ft)
end

local function should_skip_tag(name)
  if config.include_intrinsic then
    return false
  end

  return name:match("^[%l%-]+$") ~= nil
end

local function get_query(lang)
  lang = lang or config.lang
  if query_cache[lang] ~= nil then
    return query_cache[lang]
  end

  local ok, parsed = pcall(vim.treesitter.query.parse, lang, tsx_query)
  if ok then
    query_cache[lang] = parsed
    return parsed
  else
    return nil
  end
end

local function get_parser(bufnr)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, config.lang)
  if ok then
    return parser
  end
end

local function redraw(bufnr)
  if vim.api.nvim__redraw then
    pcall(vim.api.nvim__redraw, { buf = bufnr, valid = true, flush = false })
    return
  end

  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.cmd.redraw()
    end
  end)
end

local function hash_name(name)
  local hash = 0
  for i = 1, #name do
    hash = (hash * 33 + name:byte(i)) % 2147483647
  end
  return hash
end

local function group_for_tag(name, index)
  local groups = config.highlight_groups
  if #groups == 0 then
    return nil
  end

  if config.strategy == "sequence" then
    return groups[((index - 1) % #groups) + 1]
  end

  return groups[(hash_name(name) % #groups) + 1]
end

local function render_range(bufnr, topline, botline)
  if not enabled_buffers[bufnr] or not config.enabled or not is_supported_filetype(bufnr) then
    return
  end

  local query = get_query(config.lang)
  if not query then
    return
  end

  local parser = get_parser(bufnr)
  if not parser then
    return
  end

  local ok, trees = pcall(parser.parse, parser)
  if not ok or not trees or not trees[1] then
    return
  end

  local root = trees[1]:root()
  local tag_index = 0

  for _, node in query:iter_captures(root, bufnr, topline, botline + 1) do
    local start_row, start_col, end_row, end_col = node:range()
    if start_row <= botline and end_row >= topline then
      local name = vim.treesitter.get_node_text(node, bufnr)
      if name and name ~= "" and not should_skip_tag(name) then
        tag_index = tag_index + 1
        local hl_group = group_for_tag(name, tag_index)
        if hl_group then
          vim.api.nvim_buf_set_extmark(bufnr, ns, start_row, start_col, {
            end_row = end_row,
            end_col = end_col,
            hl_group = hl_group,
            priority = 120,
            ephemeral = true,
          })
        end
      end
    end
  end
end

local function attach_provider()
  if provider_attached then
    return
  end

  provider_attached = true
  vim.api.nvim_set_decoration_provider(ns, {
    on_win = function(_, winid, bufnr, topline, botline)
      if not vim.api.nvim_win_is_valid(winid) or not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end

      render_range(bufnr, topline, botline)
    end,
  })
end

function M.enable(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  enabled_buffers[bufnr] = true
  redraw(bufnr)
end

function M.disable(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  enabled_buffers[bufnr] = nil
  redraw(bufnr)
end

function M.toggle(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if enabled_buffers[bufnr] then
    M.disable(bufnr)
  else
    M.enable(bufnr)
  end
end

function M.is_enabled(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return enabled_buffers[bufnr] == true
end

function M.setup(user_config)
  merge(user_config)
  create_default_highlights()
  attach_provider()

  vim.api.nvim_create_augroup("RainbowTags", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = "RainbowTags",
    callback = create_default_highlights,
  })

  vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
    group = "RainbowTags",
    callback = function(event)
      if config.enabled and is_supported_filetype(event.buf) then
        M.enable(event.buf)
      end
    end,
  })

  vim.api.nvim_create_user_command("RainbowTagsEnable", function(opts)
    M.enable(opts.args ~= "" and tonumber(opts.args) or nil)
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("RainbowTagsDisable", function(opts)
    M.disable(opts.args ~= "" and tonumber(opts.args) or nil)
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("RainbowTagsToggle", function(opts)
    M.toggle(opts.args ~= "" and tonumber(opts.args) or nil)
  end, { nargs = "?" })

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and config.enabled and is_supported_filetype(bufnr) then
      M.enable(bufnr)
    end
  end
end

function M.get_config()
  return vim.deepcopy(config)
end

return M
