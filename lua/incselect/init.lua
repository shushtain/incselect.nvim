local M = {}

M.nodes = {}

---Selects node around cursor and clears history
---@return boolean result
function M.init()
  local utils = require("incselect.utils")
  local bufnr = vim.api.nvim_get_current_buf()

  if utils.parse(bufnr) then
    local node = vim.treesitter.get_node({
      bufnr = bufnr,
      ignore_injections = false,
    })
    if node then
      M.nodes[bufnr] = { node }
      utils.select(bufnr, node)
      return true
    end
  end

  return false
end

---If node is selected, selects its parent.
---Otherwise, selects node for range and clears history
---@return boolean result
function M.parent()
  local utils = require("incselect.utils")
  return utils.process(M.nodes, function(bufnr, parser, _, selection)
    local offset = utils.offset(selection)
    local parent = nil

    parser = parser:language_for_range(offset)
    while parser and not parent do
      parent = parser:named_node_for_range(offset)
      while parent and utils.match(bufnr, parent, selection) do
        parent = parent:parent()
      end
      ---@diagnostic disable-next-line: assign-type-mismatch
      parser = parser:parent()
    end

    return parent
  end)
end

---If node is selected, selects its first child.
---Otherwise, selects node for range and clears history
---@return boolean result
function M.child()
  local utils = require("incselect.utils")
  return utils.process(M.nodes, function(_, _, node, _)
    return node:named_child(0)
  end)
end

---If node is selected, selects its next sibling.
---If on last sibling, selects first sibling.
---Otherwise, selects node for range and clears history
---@return boolean result
function M.next()
  local utils = require("incselect.utils")
  return utils.process(M.nodes, function(_, _, node, _)
    local sibling = node:next_named_sibling()
    if not sibling then
      local parent = node:parent()
      if parent then
        sibling = parent:named_child(0)
      end
    end
    return sibling
  end)
end

---If node is selected, selects its previous sibling.
---If on first sibling, selects last sibling.
---Otherwise, selects node for range and clears history
---@return boolean result
function M.prev()
  local utils = require("incselect.utils")
  return utils.process(M.nodes, function(_, _, node, _)
    local sibling = node:prev_named_sibling()
    if not sibling then
      local parent = node:parent()
      if parent then
        local children = parent:named_child_count()
        sibling = parent:named_child(children - 1)
      end
    end
    return sibling
  end)
end

---If history has at least two nodes, selects previous node.
---Otherwise, keeps current selection
---@return boolean result
function M.undo()
  local bufnr = vim.api.nvim_get_current_buf()
  if M.nodes[bufnr] and #M.nodes[bufnr] > 1 then
    table.remove(M.nodes[bufnr])
    local node = M.nodes[bufnr][#M.nodes[bufnr]]
    ---@diagnostic disable-next-line: param-type-mismatch
    require("incselect.utils").select(bufnr, node)
    return true
  end
  return false
end
return M
