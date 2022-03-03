#!/usr/bin/env tarantool

local socket = require('socket')
local tap = require('tap')
package.cpath = './?.so;' .. package.cpath
local memcached = require('memcached')
local test = tap.test('memcached module api')

local function is_port_open(port)
    local sock, _ = socket.tcp_connect('127.0.0.1', port)
    if sock == nil then
        return false
    end
    return true
end

if type(box.cfg) == 'function' then
    box.cfg{
        wal_mode = 'none',
        memtx_memory = 100 * 1024 * 1024,
    }
    box.schema.user.grant('guest', 'read,write,execute', 'universe')
end

test:plan(15)

-- memcached.server: module is initialized, no instances

test:istable(memcached.server, 'type of memcached.server is a table')
test:is(#memcached.server, 0, 'memcached.server is empty')

-- memcached.create(): instance 1

local mc_1_port = 11211
local mc_1_name = 'memcached_1_xxx'
local mc_1_space_name = 'memcached_1_xxx_space'

local mc_1 = memcached.create(mc_1_name, tostring(mc_1_port), {
    space_name = mc_1_space_name
})
test:isnt(mc_1, nil, '1st memcached instance object is not nil')
test:is(is_port_open(mc_1_port), true, '1st memcached instance is started')
mc_1:stop()

-- memcached.create(): instance 2

local mc_2_port = 11212
local mc_2_name = 'memcached_2_xxx'
local mc_2_space_name = 'memcached_2_xxx_space'

local mc_2 = memcached.create(mc_2_name, tostring(mc_2_port), {
    space_name = mc_2_space_name
})
test:isnt(mc_2, nil, '2nd memcached instance object is not nil')
test:is(is_port_open(mc_2_port), true, '2nd memcached instance is started')
mc_2:stop()

-- memcached.server with created and started instances

mc_1:start()
mc_2:start()

test:istable(memcached.server, 'type of memcached.server is a table')
test:is(#memcached.server, 0, 'memcached.server is empty')

mc_1:stop()
mc_2:stop()

-- memcached.get()

test:is(memcached.get(), nil, 'memcached.get() without arguments returns nil')

-- memcached.get(instance_1_name)

local instance_1_info = memcached.get(mc_1_name)
test:is(instance_1_info.name, mc_1.name, 'memcached.get(): name of instance 1 is correct')
test:is(instance_1_info.space_name, mc_1.space_name, 'memcached.get(): space name of instance 1 is correct')
test:is(instance_1_info.space.id, mc_1.space.id, 'memcached.get(): space id of instance 1 is correct')

-- memcached.get(instance_2_name)

local instance_2_info = memcached.get(mc_2_name)
test:is(instance_2_info.name, mc_2.name, 'memcached.get(): name of instance 2 is correct')
test:is(instance_2_info.space_name, mc_2.space_name, 'memcached.get(): space name of instance 2 is correct')
test:is(instance_2_info.space.id, mc_2.space.id, 'memcached.get(): space id of instance 2 is correct')

os.exit(test:check() and 0 or 1)