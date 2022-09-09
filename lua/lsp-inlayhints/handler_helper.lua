local config = require "lsp-inlayhints.config"
local opts = config.options.inlay_hints

local get_type_vt = function(current_line, labels)
  if not (opts.type_hints.show and next(labels)) then
    return ""
  end

  -- TODO Replace this block with a generic function
  -- we can remove .show option (a function may return empty)
  -- we can remove .separator
  return table.concat(labels or {}, opts.type_hints.separator)
end

local get_param_vt = function(labels)
  if not (opts.parameter_hints.show and next(labels)) then
    return ""
  end

  -- TODO Replace this block with a generic function
  -- we can remove .show option after (a function may return empty)
  return table.concat(labels or {}, opts.parameter_hints.separator)
end

local fill_labels = function(hint)
  local tbl = {}

  -- label may be a string or InlayHintLabelPart[]
  -- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#inlayHintLabelPart
  if type(hint.label) == "table" then
    for _, label_part in ipairs(hint.label) do
      tbl[#tbl + 1] = label_part.value
    end
  else
    tbl[#tbl + 1] = hint.label
  end

  return tbl
end

local render_hints = function(bufnr, parsed, namespace, range)
  if config.options.inlay_hints.only_current_line then
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1] - 1
    parsed = vim.tbl_filter(function(h)
      return h.position.line == line
    end, parsed)
  end

  for _, hint in ipairs(parsed) do
    local label

    local labels = fill_labels(hint)
    if hint.kind == 2 then
      -- Parameter label
      -- TODO accept a generic fn
      label = get_param_vt(labels)
    else
      -- Type label or other
      -- TODO accept a generic fn
      label = get_type_vt(nil, labels)
    end

    if label ~= "" then
      local line_start, line_end = range.start[1], range._end[1]
      local line = hint.position.line
      local col = hint.position.character
      if line >= line_start and line <= line_end then
        local virt_text = {}
        if hint.paddingLeft then
          virt_text[#virt_text + 1] = { " ", "Normal" }
        end
        virt_text[#virt_text + 1] = { label, config.options.inlay_hints.highlight }
        if hint.paddingRight then
          virt_text[#virt_text + 1] = { " ", "Normal" }
        end

        -- TODO col value outside range
        vim.api.nvim_buf_set_extmark(bufnr, namespace, line, col, {
          virt_text = virt_text,
          virt_text_pos = "inline",
          -- strict = false,
        })
      end
    end
  end
end

return {
  render_hints = render_hints,
}
