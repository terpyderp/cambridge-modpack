local Object = require 'libs.classic'

local LifeGrid = Object:extend()

local empty = { skin = "", colour = "" }
local oob = { skin = "", colour = "" }
local block = { skin = "2tie", colour = "A" }

function LifeGrid:new(width, height)
	self.grid = {}
	self.grid_age = {}
	self.width = width
	self.height = height
	for y = 1, self.height do
		self.grid[y] = {}
		self.grid_age[y] = {}
		for x = 1, self.width do
			self.grid[y][x] = empty
			self.grid_age[y][x] = 0
		end
	end
end

function LifeGrid:clear()
	for y = 1, self.height do
		for x = 1, self.width do
			self.grid[y][x] = empty
			self.grid_age[y][x] = 0
		end
	end
end

function LifeGrid:getCell(x, y)
	if x < 1 or x > self.width or y > self.height then return oob
	elseif y < 1 then return empty
	else return self.grid[y][x]
	end
end

function LifeGrid:isOccupied(x, y)
	return self:getCell(x+1, y+1) ~= empty
end

function LifeGrid:isRowFull(row)
	for index, square in pairs(self.grid[row]) do
		if square == empty then return false end
	end
	return true
end

function LifeGrid:canPlacePiece(piece)
	if piece.big then
		return self:canPlaceBigPiece(piece)
	end

	local offsets = piece:getBlockOffsets()
	for index, offset in pairs(offsets) do
		local x = piece.position.x + offset.x
		local y = piece.position.y + offset.y
		if self:isOccupied(x, y) then
			return false
		end
	end
	return true
end

function LifeGrid:canPlaceBigPiece(piece)
	local offsets = piece:getBlockOffsets()
	for index, offset in pairs(offsets) do
		local x = piece.position.x + offset.x
		local y = piece.position.y + offset.y
		if (
		   self:isOccupied(x * 2 + 0, y * 2 + 0)
		or self:isOccupied(x * 2 + 1, y * 2 + 0)
		or self:isOccupied(x * 2 + 0, y * 2 + 1)
		or self:isOccupied(x * 2 + 1, y * 2 + 1)
		) then
			return false
		end
	end
	return true
end

function LifeGrid:canPlacePieceInVisibleLifeGrid(piece)
	if piece.big then
		return self:canPlaceBigPiece(piece)
		-- forget canPlaceBigPieceInVisibleLifeGrid for now
	end

	local offsets = piece:getBlockOffsets()
	for index, offset in pairs(offsets) do
		local x = piece.position.x + offset.x
		local y = piece.position.y + offset.y
		if y < 4 or self:isOccupied(x, y) ~= empty then
			return false
		end
	end
	return true
end

function LifeGrid:getClearedRowCount()
	local count = 0
	local cleared_row_table = {}
	for row = 1, self.height do
		if self:isRowFull(row) then
			count = count + 1
			table.insert(cleared_row_table, row)
		end
	end
	return count, cleared_row_table
end

function LifeGrid:markClearedRows()
	local block_table = {}
	for row = 1, self.height do
		if self:isRowFull(row) then
			block_table[row] = {}
			for x = 1, self.width do
				block_table[row][x] = {
					skin = self.grid[row][x].skin,
					colour = self.grid[row][x].colour,
				}
				self.grid[row][x] = {
					skin = self.grid[row][x].skin,
					colour = "X"
				}
				--self.grid_age[row][x] = 0
			end
		end
	end
	return block_table
end

function LifeGrid:clearClearedRows()
	for row = 1, self.height do
		if self:isRowFull(row) then
			for above_row = row, 2, -1 do
				self.grid[above_row] = self.grid[above_row - 1]
				self.grid_age[above_row] = self.grid_age[above_row - 1]
			end
			self.grid[1] = {}
			self.grid_age[1] = {}
			for i = 1, self.width do
				self.grid[1][i] = empty
				self.grid_age[1][i] = 0
			end
		end
	end
	return true
end

function LifeGrid:copyBottomRow()
	for row = 1, self.height - 1 do
		self.grid[row] = self.grid[row+1]
		self.grid_age[row] = self.grid_age[row+1]
	end
	self.grid[self.height] = {}
	self.grid_age[self.height] = {}
	for i = 1, self.width do
		self.grid[self.height][i] = (self.grid[self.height - 1][i] == empty) and empty or block
		self.grid_age[self.height][i] = 0
	end
	return true
end

function LifeGrid:garbageRise(row_vals)
	for row = 1, self.height - 1 do
		self.grid[row] = self.grid[row+1]
		self.grid_age[row] = self.grid_age[row+1]
	end
	self.grid[self.height] = {}
	self.grid_age[self.height] = {}
	for i = 1, self.width do
		self.grid[self.height][i] = (row_vals[i] == "e") and empty or block
		self.grid_age[self.height][i] = 0
	end
end

function LifeGrid:clearSpecificRow(row)
	for col = 1, self.width do
		self.grid[row][col] = empty
	end
end

function LifeGrid:applyPiece(piece)
	if piece.big then
		self:applyBigPiece(piece)
		return
	end
	offsets = piece:getBlockOffsets()
	for index, offset in pairs(offsets) do
		x = piece.position.x + offset.x
		y = piece.position.y + offset.y
		if y + 1 > 0 and y < self.height then
			self.grid[y+1][x+1] = {
				skin = piece.skin,
				colour = piece.colour
			}
		end
	end
end

function LifeGrid:applyBigPiece(piece)
	offsets = piece:getBlockOffsets()
	for index, offset in pairs(offsets) do
		x = piece.position.x + offset.x
		y = piece.position.y + offset.y
		for a = 1, 2 do
			for b = 1, 2 do
				if y*2+a > 0 and y*2 < self.height then
					self.grid[y*2+a][x*2+b] = {
						skin = piece.skin,
						colour = piece.colour
					}
				end
			end
		end
	end
end

function LifeGrid:checkForBravo(cleared_row_count)
	for i = 0, self.height - 1 - cleared_row_count do
				for j = 0, self.width - 1 do
						if self:isOccupied(j, i) then return false end
				end
		end
	return true
end

function LifeGrid:checkStackHeight()
	for i = 0, self.height - 1 do
		for j = 0, self.width - 1 do
			if self:isOccupied(j, i) then return self.height - i end
		end
	end
	return 0
end

function LifeGrid:checkSecretGrade()
	local sgrade = 0
	for i=23,5,-1 do
		local validLine = true
		local emptyCell = 0
		if i > 13 then
			emptyCell = 23-i
		end
		if i <= 13 then
			emptyCell = i-5
		end
		for j=0,9 do
			if (not self:isOccupied(j,i) and j ~= emptyCell) or (j == emptyCell and self:isOccupied(j,i)) then
				validLine = false
			end
		end
		if not self:isOccupied(emptyCell,i-1) then
			validLine = false
		end
		if(validLine) then
				sgrade = sgrade + 1
		else
				return sgrade
		end
	end
	--[[
	if(sgrade == 0) then return ""
	elseif(sgrade < 10) then return 10-sgrade
	elseif(sgrade < 19) then return "S"..(sgrade-9) end
	return "GM"
	--]]
	return sgrade
end

function LifeGrid:hasGemBlocks()
	for y = 1, self.height do
		for x = 1, self.width do
			if self.grid[y][x].skin == "gem" then
				return true
			end
		end
	end
	return false
end

function LifeGrid:mirror()
	local new_grid = {}
	for y = 1, self.height do
		new_grid[y] = {}
		for x = 1, self.width do
			new_grid[y][x] = empty
		end
	end

	for y = 1, self.height do
		for x = 1, self.width do
			new_grid[y][x] = self.grid[y][self.width + 1 - x]
		end
	end
	self.grid = new_grid
end

function LifeGrid:applyMap(map)
	for y, row in pairs(map) do
		for x, block in pairs(row) do
			self.grid_age[y][x] = 0
			self.grid[y][x] = block
		end
	end
end

-- inefficient algorithm for squares
function LifeGrid:markSquares()
	-- goes up by 1 for silver, 2 for gold
	local square_count = 0
	for i = 1, 2 do
		for y = 5, self.height - 3 do
			for x = 1, self.width - 3 do
				local age_table = {}
				local age_count = 0
				local colour_table = {}
				local is_square = true
				for j = 0, 3 do
					for k = 0, 3 do
						if self.grid[y+j][x+k].skin == "" or self.grid[y+j][x+k].skin == "square" then
							is_square = false
						end
						if age_table[self.grid_age[y+j][x+k]] == nil then
							age_table[self.grid_age[y+j][x+k]] = 1
							age_count = age_count + 1
						else
							age_table[self.grid_age[y+j][x+k]] = age_table[self.grid_age[y+j][x+k]] + 1
						end
						if age_count > 4 or age_table[self.grid_age[y+j][x+k]] > 4 then
							is_square = false
						end
						if not table.contains(colour_table, self.grid[y+j][x+k].colour) then
							table.insert(colour_table, self.grid[y+j][x+k].colour)
						end
					end
				end
				if is_square then
					if i == 1 and #colour_table == 1 then
						for j = 0, 3 do
							for k = 0, 3 do
								self.grid[y+j][x+k].colour = "Y"
								self.grid[y+j][x+k].skin = "square"
							end
						end
						square_count = square_count + 2
					elseif i == 2 then
						for j = 0, 3 do
							for k = 0, 3 do
								self.grid[y+j][x+k].colour = "W"
								self.grid[y+j][x+k].skin = "square"
							end
							
						end
						square_count = square_count + 1
					end
				end
			end
		end
	end
	return square_count
end

-- square scan
function LifeGrid:scanForSquares()
	local table = {}
	for row = 1, self.height do
		local silver = 0
		local gold = 0
		for col = 1, self.width do
			local colour = self.grid[row][col].colour
			if self.grid[row][col].skin == "square" then
				if colour == "Y" then gold = gold + 1
				else silver = silver + 1 end
			end
		end
		table[row] = gold * 2.5 + silver * 1.25
	end
	return table
end

function LifeGrid:update()
	for y = 1, self.height do
		for x = 1, self.width do
			if self.grid[y][x] ~= empty then
				self.grid_age[y][x] = self.grid_age[y][x] + 1
			end
		end
	end
end

function LifeGrid:draw()
	for y = 5, self.height do
		for x = 1, self.width do
			if blocks[self.grid[y][x].skin] and
			blocks[self.grid[y][x].skin][self.grid[y][x].colour] then
				if self.grid_age[y][x] < 2 then
					love.graphics.setColor(1, 1, 1, 1)
					love.graphics.draw(blocks[self.grid[y][x].skin]["F"], 48+x*16, y*16)
				else
					if self.grid[y][x].colour == "X" then
						love.graphics.setColor(0, 0, 0, 0)
					elseif self.grid[y][x].skin == "bone" then
						love.graphics.setColor(1, 1, 1, 1)
					else
						love.graphics.setColor(0.5, 0.5, 0.5, 1)
					end
					love.graphics.draw(blocks[self.grid[y][x].skin][self.grid[y][x].colour], 48+x*16, y*16)
				end
				if self.grid[y][x].skin ~= "bone" and self.grid[y][x].colour ~= "X" then
					love.graphics.setColor(0.8, 0.8, 0.8, 1)
					love.graphics.setLineWidth(1)
					if y > 5 and self.grid[y-1][x] == empty or self.grid[y-1][x].colour == "X" then
						love.graphics.line(48.0+x*16, -0.5+y*16, 64.0+x*16, -0.5+y*16)
					end
					if y < self.height and self.grid[y+1][x] == empty or
					(y + 1 <= self.height and self.grid[y+1][x].colour == "X") then
						love.graphics.line(48.0+x*16, 16.5+y*16, 64.0+x*16, 16.5+y*16)
					end
					if x > 1 and self.grid[y][x-1] == empty then
						love.graphics.line(47.5+x*16, -0.0+y*16, 47.5+x*16, 16.0+y*16)
					end
					if x < self.width and self.grid[y][x+1] == empty then
						love.graphics.line(64.5+x*16, -0.0+y*16, 64.5+x*16, 16.0+y*16)
					end
				end
			end
		end
	end
end

function LifeGrid:drawOutline()
	for y = 5, self.height do
		for x = 1, self.width do
			if self.grid[y][x] ~= empty and self.grid[y][x].colour ~= "X" then
				love.graphics.setColor(0.8, 0.8, 0.8, 1)
				love.graphics.setLineWidth(1)
				if y > 5 and self.grid[y-1][x] == empty or self.grid[y-1][x].colour == "X" then
					love.graphics.line(48.0+x*16, -0.5+y*16, 64.0+x*16, -0.5+y*16)
				end
				if y < self.height and self.grid[y+1][x] == empty or
				(y + 1 <= self.height and self.grid[y+1][x].colour == "X") then
					love.graphics.line(48.0+x*16, 16.5+y*16, 64.0+x*16, 16.5+y*16)
				end
				if x > 1 and self.grid[y][x-1] == empty then
					love.graphics.line(47.5+x*16, -0.0+y*16, 47.5+x*16, 16.0+y*16)
				end
				if x < self.width and self.grid[y][x+1] == empty then
					love.graphics.line(64.5+x*16, -0.0+y*16, 64.5+x*16, 16.0+y*16)
				end
			end
		end
	end
end

function LifeGrid:drawInvisible(opacity_function, garbage_opacity_function, lock_flash, brightness)
	lock_flash = lock_flash == nil and true or lock_flash
	brightness = brightness == nil and 0.5 or brightness
	for y = 5, self.height do
		for x = 1, self.width do
			if self.grid[y][x] ~= empty then
				if self.grid[y][x].colour == "X" then
					opacity = 0
				elseif garbage_opacity_function and self.grid[y][x].colour == "A" then
					opacity = garbage_opacity_function(self.grid_age[y][x])
				else
					opacity = opacity_function(self.grid_age[y][x])
				end
				love.graphics.setColor(brightness, brightness, brightness, opacity)
				love.graphics.draw(blocks[self.grid[y][x].skin][self.grid[y][x].colour], 48+x*16, y*16)
				if lock_flash then
					if opacity > 0 and self.grid[y][x].colour ~= "X" then
						love.graphics.setColor(0.64, 0.64, 0.64)
						love.graphics.setLineWidth(1)
						if y > 5 and self.grid[y-1][x] == empty or self.grid[y-1][x].colour == "X" then
							love.graphics.line(48.0+x*16, -0.5+y*16, 64.0+x*16, -0.5+y*16)
						end
						if y < self.height and self.grid[y+1][x] == empty or
						(y + 1 <= self.height and self.grid[y+1][x].colour == "X") then
							love.graphics.line(48.0+x*16, 16.5+y*16, 64.0+x*16, 16.5+y*16)
						end
						if x > 1 and self.grid[y][x-1] == empty then
							love.graphics.line(47.5+x*16, -0.0+y*16, 47.5+x*16, 16.0+y*16)
						end
						if x < self.width and self.grid[y][x+1] == empty then
							love.graphics.line(64.5+x*16, -0.0+y*16, 64.5+x*16, 16.0+y*16)
						end
					end
				end
			end
		end
	end
end

function LifeGrid:drawCustom(colour_function, gamestate)
    --[[
        colour_function: (game, block, x, y, age) -> (R, G, B, A, outlineA)
        When called, calls the supplied function on every block passing the block itself as argument
        as well as coordinates and the grid_age value of the same cell.
        Should return a RGBA colour for the block, as well as the opacity of the stack outline (0 for no outline).
        
        gamestate: the gamemode instance itself to pass in colour_function
    ]]
	for y = 5, self.height do
		for x = 1, self.width do
            local block = self.grid[y][x]
			if block ~= empty then
                local R, G, B, A, outline = colour_function(gamestate, block, x, y, self.grid_age[y][x])
				if self.grid[y][x].colour == "X" then
					A = 0
				end
				love.graphics.setColor(R, G, B, A)
				love.graphics.draw(blocks[self.grid[y][x].skin][self.grid[y][x].colour], 48+x*16, y*16)
                if outline > 0 and self.grid[y][x].colour ~= "X" then
                    love.graphics.setColor(0.64, 0.64, 0.64, outline)
                    love.graphics.setLineWidth(1)
                    if y > 5 and self.grid[y-1][x] == empty or self.grid[y-1][x].colour == "X" then
						love.graphics.line(48.0+x*16, -0.5+y*16, 64.0+x*16, -0.5+y*16)
					end
					if y < self.height and self.grid[y+1][x] == empty or
					(y + 1 <= self.height and self.grid[y+1][x].colour == "X") then
						love.graphics.line(48.0+x*16, 16.5+y*16, 64.0+x*16, 16.5+y*16)
					end
					if x > 1 and self.grid[y][x-1] == empty then
						love.graphics.line(47.5+x*16, -0.0+y*16, 47.5+x*16, 16.0+y*16)
					end
					if x < self.width and self.grid[y][x+1] == empty then
						love.graphics.line(64.5+x*16, -0.0+y*16, 64.5+x*16, 16.0+y*16)
					end
                end
			end
		end
	end
end

function LifeGrid:advanceLife()
	local newgrid = {}
	local newgrid_age = {}
	for y = 1, self.height do
		newgrid[y] = {}
		newgrid_age[y] = {}
		for x = 1, self.width do
			newgrid[y][x] = empty
			newgrid_age[y][x] = 0
		end
	end
	for y = 1, self.height do
		for x = 1, self.width do
			count = 0
			for dy = -1, 1 do
				for dx = -1, 1 do
					if (dy~=0 or dx~=0) and self.grid[dy+y] and self.grid[dy+y][dx+x] and self.grid[dy+y][dx+x] ~= empty then
						count = count + 1
					end
				end
			end
			if (count > 1) and (count < 4) then
				newgrid[y][x] = self.grid[y][x]
				if (count == 3) and (newgrid[y][x] == empty) then
					newgrid[y][x] = {
						skin = "2tie",
						colour = ({"R", "O", "Y", "G", "B", "C", "M"})[math.random(7)]
					}
				end
			end
		end
	end
	self.grid=newgrid
	self.grid_age=newgrid_age
end

return LifeGrid
