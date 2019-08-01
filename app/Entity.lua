local M = class("Entity")

function M:ctor(ctx)
    if ctx then
        self.ctx = ctx
    end

    self.uid = 0
    self.comps = {}
end

-- TODO 检查配置里的这个值
function M:create_index_key(k, v)
    assert(v, "index value nil is not allowed")
    local oldv = self[k]
    if oldv == v then return end
    self[k] = v

    if not self.ctx then return end

    if not self.ctx:is_idx(k) then return end
    if oldv then--移除原先的
        local g = self.ctx:get_idx_vs(k, oldv)
        g:remove(self)
        if g:size() == 0 then
            --TODO 要不要清除g
        end
    end
    local g = self.ctx:get_idx_vs(k, v)
    g:insert(self)
end

-- 删除索引
function M:delete_index_key(k)
    local oldv = self[k]
    if not oldv then return end
    self[k] = nil

    if not self.ctx then return end

    local g = self.ctx:is_idx_vs(k, oldv)
    if not g then return end
    g:remove(self)
    if g:size() == 0 then
        self.ctx:del_idx_vs(k, oldv)
    end
end

-- 创建一个主键索引字段
-- TODO 检查配置里的这个值
function M:create_primary_key(k, v)
    assert(v, "index value nil is not allowed")
    local oldv = self[k]
    if oldv == v then return end
    self[k] = v

    if not self.ctx then return end
    local g = self.ctx:is_primary_idx(k)
    if not g then return end

    if oldv then--删除原先的
        g[oldv] = nil
    end
    g[v] = self
end

function M:detele_primary_key(k)
    local oldv = self[k]
    if not oldv then return end
    self[k] = nil

    if not self.ctx then return end
    local g = self.ctx:is_primary_idx(k)
    if not g then return end
    g[oldv] = nil
end

function M:newuid(uid)
    if self.uid == uid then return end
    if not self.ctx then return end

    -- 业务上要保证唯一，否则会失败
    if self.ctx.entities[uid] then error("is uid? no no no") end
    self.ctx.entities[self.uid] = nil
    self.uid = uid
    self.ctx.entities[uid] = self
end

function M:get(comp)
    return self.comps[comp]
end

-- 聚类
function M:add(comp, args)
    if args then
        self.comps[comp] = args
    else
        self.comps[comp] = true
    end

    if not self.ctx then return end
    local g = self.ctx:isget_group(comp)
    if not g then return end
    g:insert(self)
end

-- 移除聚类
function M:remove(comp)
    if not self.comps[comp] then return end

    self.comps[comp] = nil

    if not self.ctx then return end
    local g = self.ctx:isget_group(comp)
    if g then
        g:remove(self)
    end
end

function M:has(comp)
    return self.comps[comp]
end

function M:has_all(comps)
    if not comps or #comps == 0 then
        return false
    end

    for _, comp in pairs(comps) do
        if not self.comps[comp] then
            return false
        end
    end
    return true
end

function M:remove_all()
    for k in pairs(self.comps) do
        self:remove(k)
    end
end

function M:destroy()
    self:remove_all()

    if not self.ctx then return end

    local ctx = self.ctx
    self.ctx = nil
    for k, v in pairs(ctx._primary_idxs) do
        if self[k] then
            v[self[k]] = nil
        end
    end

    for k, gs in pairs(ctx._idxs) do
        if self[k] and gs[self[k]] then
            gs[self[k]]:remove(self)
            if gs[self[k]]:size() == 0 then
                gs[self[k]] = nil
            end
            if not next(gs) then
                ctx._idxs[k] = nil
            end
        end
    end
end

return M
