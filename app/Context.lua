local Entity = require("app.Entity")
local M = class("Context")

function M:ctor()
    self._uuid = 0
    self.entities = {}
    self._groups = {}
    self._idxs = {}
    self._primary_idxs = {}
end

function M:get_uuid()
    self._uuid = self._uuid + 1
    return self._uuid
end

function M:create_entity(conf)
    local entity = Entity.new(conf)
    entity.ctx = self

    self._uuid = self._uuid + 1
    entity.uid = self._uuid

    self.entities[entity.uid] = entity

    return entity
end

function M:has_entity(entity)
    return self.entities[entity.uid]
end

function M:get_entity(uid)
    return self.entities[uid]
end

function M:destroy_entity(entity)
    if not self:has_entity(entity) then
        return
    end

    entity:destroy()

    self.entities[entity.uid] = nil
end

function M:is_idx(k)
    return self._idxs[k]
end

function M:get_idx(k)
    local idx = self._idxs[k]
    if not idx then
        idx = {}
        self._idxs[k] = idx

        for _, entity in pairs(self.entities) do repeat
            local v = entity[k]
            if not v then break end
            local g = idx[v]
            if not g then
                g = {}
                idx[v] = g
            end
            g[entity] = true
        until true end
    end

    return idx
end

-- 不会创建，只检查
function M:is_idx_vs(k, v)
    if not self._idxs[k] then return end
    return self._idxs[k][v]
end
-- 如果没有会创建
function M:get_idx_vs(k, v)
    local idx = self:get_idx(k)
    if not idx[v] then
        idx[v] = {}
        for _, entity in pairs(self.entities) do repeat
            if not entity[k] then break end
            if entity[k] ~= v then break end
            idx[v][entity] = true
        until true end
    end

    return idx[v]
end

-- 删除整个索引
function M:del_idx(k)
    if not self._idxs[k] then return end
    self._idxs[k] = nil
end

-- 删除某个值的索引
function M:del_idx_vs(k, v)
    if not self._idxs[k] then return end
    if not self._idxs[k][v] then return end
    self._idxs[k][v] = nil
end

function M:is_primary_idx(k)
    return self._primary_idxs[k]
end

-- 获取主键索引
function M:get_primary_idx(k)
    local g = self._primary_idxs[k]
    if not g then
        g = {}
        for _, entity in pairs(self.entities) do repeat
            if not entity[k] then break end
            g[entity[k]] = entity
        until true end

        self._primary_idxs[k] = g
    end
    return g
end


function M:isget_group(comp)
    return self._groups[comp]
end

-- 获取拥有某个组件的组
function M:get_group(comp)
    local g = self._groups[comp]
    if not g then
        g = {}
        for _, entity in pairs(self.entities) do repeat
            if not entity:has(comp) then break end
            g[entity] = true
        until true end

        self._groups[comp] = g
    end
    return g
end

function M:del_group(comp)
    if not self._groups[comp] then
        return
    end
    self._groups[comp] = nil
end


return M
