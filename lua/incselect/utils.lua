local M = {}

---Parse tree
---@param bufnr int
---@return vim.treesitter.LanguageTree?
function M.parse(bufnr)
  local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
  local parser = vim.treesitter.get_parser(bufnr, lang, { error = false })
  if parser and type(parser) ~= "string" then
    parser:parse({ vim.fn.line("w0") - 1, vim.fn.line("w$") })
    return parser
  end
end

---Get visual selection range
---@return Range4
function M.visual()
  local _, srow, scol, _ = unpack(vim.fn.getpos("v"))
  local _, erow, ecol, _ = unpack(vim.fn.getpos("."))
  ---@diagnostic disable-next-line: assign-type-mismatch, need-check-nil
  srow, scol, erow, ecol = srow - 1, scol - 1, erow - 1, ecol - 1
  ---@diagnostic disable-next-line: return-type-mismatch
  return (srow < erow or (srow == erow and scol <= ecol))
      and { srow, scol, erow, ecol }
    or { erow, ecol, srow, scol }
end

---Normalize node:range()
---@param bufnr int
---@param node TSNode
---@return Range4
function M._normalize(bufnr, node)
  local srow, scol, erow, ecol = node:range()
  if ecol == 0 then
    erow = erow - 1
    local line = vim.fn.getbufoneline(bufnr, erow + 1)
    ecol = math.max(#line, 1)
  end
  ecol = ecol - 1
  return { srow, scol, erow, ecol }
end

---Add offset so parser can search for parents
---@param selection Range4
---@return Range4
function M.offset(selection)
  local srow, scol, erow, ecol = unpack(selection)
  return { srow, scol, erow, ecol + 1 }
end

---Check if node matches selection
---@param bufnr int
---@param node TSNode
---@param selection Range4
---@return bool
function M.match(bufnr, node, selection)
  local node_range = M._normalize(bufnr, node)
  return vim.deep_equal(node_range, selection)
end

---Select node area in buffer
---@param bufnr int
---@param node TSNode
function M.select(bufnr, node)
  local srow, scol, erow, ecol = unpack(M._normalize(bufnr, node))
  if vim.fn.mode() ~= "v" then
    vim.cmd("normal! v")
  end
  vim.api.nvim_win_set_cursor(0, { srow + 1, scol })
  vim.cmd("normal! o")
  vim.api.nvim_win_set_cursor(0, { erow + 1, ecol })
end

---Process node selection based on callback
---@param nodes table<int, TSNode[]>
---@param callback fun(bufnr: int, parser: vim.treesitter.LanguageTree, node: TSNode, selection: Range4): TSNode?
---@return boolean result
function M.process(nodes, callback)
  local bufnr = vim.api.nvim_get_current_buf()

  local parser = require("incselect.utils").parse(bufnr)
  if not parser then
    return false
  end

  local selection = require("incselect.utils").visual()
  local node = nil

  if
    not nodes[bufnr]
    or #nodes[bufnr] == 0
    or not require("incselect.utils").match(
      bufnr,
      nodes[bufnr][#nodes[bufnr]], ---@diagnostic disable-line: param-type-mismatch
      selection
    )
  then
    node = parser:named_node_for_range(selection, { ignore_injections = false })
    nodes[bufnr] = {}
  else
    ---@diagnostic disable-next-line: param-type-mismatch
    node = callback(bufnr, parser, nodes[bufnr][#nodes[bufnr]], selection)
  end

  if node then
    table.insert(nodes[bufnr], node)
    require("incselect.utils").select(bufnr, node)
    return true
  end

  return false
end

return M
