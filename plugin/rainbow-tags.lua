if vim.g.loaded_rainbow_tags == 1 then
  return
end

vim.g.loaded_rainbow_tags = 1

if vim.g.rainbow_tags_disable_auto_setup == 1 then
  return
end

require("rainbow-tags").setup(vim.g.rainbow_tags_config or {})
