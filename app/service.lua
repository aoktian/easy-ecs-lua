local moon = require("moon")

local Context = require("app.Context")
local MoveSystem = require("app.MoveSystem")

local ctx = Context.new()

local list = {}
local psid = 10000
for i = 1, 10 do
    psid = psid + 1
    list[psid] = ctx:create_entity()
    list[psid].psid = psid
    print("--------------->psid->uid", psid, list[psid].uid)
end


-- 测试组
local g_running = ctx:get_group("running")
print("--------------->g_running:size", g_running:size())
list[10001]:add("running")
list[10002]:add("running")
list[10003]:add("death")
list[10004]:add("death")
list[10005]:add("death")
print("--------------->g_running:size", g_running:size())

local g_death = ctx:get_group("death")
print("--------------->g_death:size", g_death:size())

-- 测试主键
list[10001]:create_primary_key("primary_index", 228)
list[10005]:create_primary_key("primary_index", 330)

local primary_idx = ctx:get_primary_idx("primary_index")
for k, v in pairs(primary_idx) do
    print("--------------->primary_idx", k, v.psid, v.uid, v.primary_index)
end

-- 测试索引
list[10001]:create_index_key("index", 3)
list[10006]:create_index_key("index", 3)
list[10008]:create_index_key("index", 3)
list[10002]:create_index_key("index", 8)
list[10005]:create_index_key("index", 8)
list[10009]:create_index_key("index", 8)
local indexs_3 = ctx:is_idx_vs("index", 3)
if indexs_3 then
    print("--------------->indexs_3:size", indexs_3:size())
    indexs_3:foreach(function(ref)
        print("--------------->indexs_3", ref.psid, ref.uid)
    end)
end


local indexs_8 = ctx:is_idx_vs("index", 8)
if indexs_8 then
    print("--------------->indexs_8:size", indexs_8:size())
    indexs_8:foreach(function(ref)
        print("--------------->indexs_8", ref.psid, ref.uid)
    end)
end

-- 系统其实就是模块，一般都是处理组，索引，同一类事务
local move_system = MoveSystem.new()
move_system:init(ctx)

local lastUpdateTime = moon.millsecond()
moon.repeated(1000, -1, function ()
    local t = lastUpdateTime
    lastUpdateTime = moon.millsecond()
    move_system:update(lastUpdateTime - t)
end)


-- 测试删除，组内，主键，索引都会被删除
moon.repeated(5000, 1, function ()
    ctx:destroy_entity(list[10001])
    print("--------------->g_running:size", g_running:size())
    for k, v in pairs(primary_idx) do
        print("--------------->primary_idx", k, v.psid, v.uid, v.primary_index)
    end
    print("--------------->indexs_3:size", indexs_3:size())
end)
