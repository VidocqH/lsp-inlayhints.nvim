local config = require "lsp-inlayhints.config"
local opts = config.options.inlay_hints

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

local M = {}

M.render_hints = function(bufnr, namespace, hints, range, client_name)
  if config.options.inlay_hints.only_current_line then
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1] - 1
    hints = vim.tbl_filter(function(h)
      return h.position.line == line
    end, hints)
  end

  for _, hint in ipairs(hints) do
    local labels = fill_labels(hint)
    local label = opts.label_formatter(labels, hint.kind, opts, client_name)

    if label and label ~= "" then
      local line, col = hint.position.line, hint.position.character
      local _start, _end = range.start[1], range._end[1]
      if line >= _start and line <= _end then
        local virt_text = opts.virt_text_formatter(label, hint, opts, client_name)
        if virt_text then
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
end

return M
