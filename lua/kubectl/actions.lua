local M = {}
local api = vim.api
local layout = require("kubectl.layout")

local function get_columns_to_hl(content, column_indices)
	local highlights_to_apply = {}
	local column_delimiter = "%s+"

	for i, row in ipairs(content) do
		if i > 1 then -- Skip the first line since it's column names
			local columns = {}
			for column in row:gmatch("([^" .. column_delimiter .. "]+)") do
				table.insert(columns, column)
			end
			for _, col_index in ipairs(column_indices) do
				local column = columns[col_index]
				if column then
					local start_pos, end_pos = row:find(column, 1, true)
					if start_pos and end_pos then
						table.insert(highlights_to_apply, {
							line = i - 1,
							hl_group = "@comment.note",
							start = start_pos - 1,
							stop = end_pos,
						})
					end
				end
			end
		end
	end
	return highlights_to_apply
end

local function get_lines_to_hl(content, conditions)
	local lines_to_highlight = {}
	for i, row in ipairs(content) do
		for condition, highlight in pairs(conditions) do
			local start_pos, end_pos = string.find(row, condition)
			if start_pos and end_pos then
				table.insert(
					lines_to_highlight,
					{ line = i - 1, hl_group = highlight, start = start_pos - 1, stop = end_pos }
				)
			end
		end
	end
	return lines_to_highlight
end

function M.new_buffer(content, filetype, title, opts)
	local lines_to_highlight = opts.conditions and get_lines_to_hl(content, opts.conditions)
	local highlights_to_apply = opts.columns and get_columns_to_hl(content, opts.columns)
	local buf = api.nvim_create_buf(false, true)

	api.nvim_buf_set_lines(buf, 0, -1, false, content)

	if lines_to_highlight then
		for _, line_info in ipairs(lines_to_highlight) do
			api.nvim_buf_add_highlight(buf, -1, line_info.hl_group, line_info.line, line_info.start, line_info.stop)
		end
	end

	if highlights_to_apply then
		for _, highlight_info in ipairs(highlights_to_apply) do
			api.nvim_buf_add_highlight(
				buf,
				-1,
				highlight_info.hl_group,
				highlight_info.line,
				highlight_info.start,
				highlight_info.stop
			)
		end
	end

	if opts.is_float then
		layout.float_layout(buf, filetype, title or "")
	else
		layout.main_layout(buf, filetype, title or "")
	end
end

function M.set_filetype(ft)
	api.nvim_buf_set_option(0, "filetype", ft)
end

return M
