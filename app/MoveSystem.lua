local M = class("MoveSystem")

function M:ctor()
end

function M:init(ctx)
    self.matcher = ctx:get_group("running")
end

function M:update(dt)
    self.matcher:foreach(function(ref)
        self:run(ref, dt)
    end)
end

function M:run(ref, dt)
    print("--------------->run", ref.uid, dt)
end

return M
