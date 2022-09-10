local function setInlayHintHL()
  local has_hl, hl = pcall(vim.api.nvim_get_hl_by_name, "LspInlayHint", true)
  if has_hl and (hl["foreground"] or hl["background"]) then
    return
  end

  hl = vim.api.nvim_get_hl_by_name("Comment", true)
  local foreground = string.format("#%06x", hl["foreground"] or 0)
  if #foreground < 3 then
    foreground = ""
  end

  hl = vim.api.nvim_get_hl_by_name("CursorLine", true)
  local background = string.format("#%06x", hl["background"] or 0)
  if #foreground < 3 then
    background = ""
  end

  vim.api.nvim_set_hl(0, "LspInlayHint", { fg = foreground, bg = background })
end

local config = {
  options = {},
}

local default_config = {
  inlay_hints = {
    parameter_hints = {
      show = true,
    },
    -- type and other hints
    type_hints = {
      show = true,
    },
    only_current_line = false,
    label_formatter = function(labels, kind, opts, client_name)
      if kind == 2 and not opts.parameter_hints.show then
        return ""
      elseif not opts.type_hints.show then
        return ""
      end

      return table.concat(labels or {}, ", ")
    end,
    virt_text_formatter = function(label, hint, opts, client_name)
      if client_name == "sumneko_lua" then
        if hint.kind == 2 then
          hint.paddingLeft = false
        end
      end

      local virt_text = {}
      virt_text[#virt_text + 1] = hint.paddingLeft and { " ", "Normal" } or nil
      virt_text[#virt_text + 1] = { label, opts.highlight }
      virt_text[#virt_text + 1] = hint.paddingRight and { " ", "Normal" } or nil

      return virt_text
    end,

    -- highlight group
    highlight = "LspInlayHint",
  },
  enabled_at_startup = true,
  debug_mode = false,
}

config.load = function(user_config)
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("_InlayHintsColorscheme", {}),
    pattern = "*",
    callback = setInlayHintHL,
  })

  setInlayHintHL()
  config.options = vim.tbl_deep_extend("force", default_config, user_config or {})
end

return config
