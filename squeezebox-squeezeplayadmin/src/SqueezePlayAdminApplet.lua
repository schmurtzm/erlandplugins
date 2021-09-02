
--[[
=head1 NAME

applets.SqueezePlayAdmin.SqueezePlayAdminApplet - File Server applet

=head1 DESCRIPTION

SqueezePlay Admin is an applet that makes it possible to access a SqueezePlay remotely from a plugin
in a known Squeezebox Server

=head1 FUNCTIONS

Applet related methods are described in L<jive.Applet>. SqueezePlayAdminApplet overrides the
following methods:

=cut
--]]


-- stuff we use
local pairs, ipairs, tostring, tonumber, package = pairs, ipairs, tostring, tonumber, package

local oo               = require("loop.simple")
local os               = require("os")
local io               = require("io")
local string           = require("jive.utils.string")

local System           = require("jive.System")
local Applet           = require("jive.Applet")
local Framework        = require("jive.ui.Framework")

local lfs              = require("lfs")
local mime             = require("mime")
local math             = require("math")

local appletManager    = appletManager
local jiveMain         = jiveMain
local jnt              = jnt

module(..., Framework.constants)
oo.class(_M, Applet)


----------------------------------------------------------------------------------------
-- Helper Functions
--

function init(self)
	math.randomseed(os.clock())
	jnt:subscribe(self)
end

function squeezePlayAdminDispatch(self,cmd,applet,method,binarycommand,binaryresponse)
	if not self.cmds then
		self.cmds = {}
	end
	self.cmds[cmd] = {
		applet = applet,
		method = method,
		binarycommand = binarycommand,
		binaryresponse = binaryresponse
	}
	log:debug("Registering "..cmd.." as:"..applet..","..method..","..tostring(binarycommand)..","..tostring(self.cmds[cmd].binaryresponse))
	if self.servers then
		for secret,server in pairs(self.servers) do
			self:subscribeForCommand(server,cmd)
		end
	end
end

function dirCommand(self,params)
	local dir = params.dir
	log:debug("Getting files for "..tostring(dir))
	local subdirs = lfs.dir(dir)
	local files = {}
	local no = 1
	for file in subdirs do
		if file == ".." then
			if dir ~= "/" then
				local parentdir = dir
				parentdir = string.gsub(parentdir,"/[^/]+$","")
				files[no] = { 
					fullpath = parentdir,
					name = file,
					type = lfs.attributes(dir.."/"..file,"mode"),
					size = lfs.attributes(dir.."/"..file,"size")
				}
				no = no +1
			end
		elseif file ~= "." then
			local separator = "/"
			if dir == "/" then
				separator = ""
			end
			files[no] = { 
				fullpath = dir..separator..file,
				name = file,
				type = lfs.attributes(dir..separator..file,"mode"),
				size = lfs.attributes(dir..separator..file,"size")
			}
			no = no +1
		end
	end
	
	local result = {
		files = files
	}
	return result
end

function appletsCommand(self,params)

	local no = 1
	local applets = {}
        -- Find all applets/* directories on lua path
        for dir in package.path:gmatch("([^;]*)%?[^;]*;") do repeat
        
                dir = dir .. "applets"
                log:debug("..in ", dir)
                
                local mode = lfs.attributes(dir, "mode")
                if mode ~= "directory" then
                        break
                end

                for entry in lfs.dir(dir) do repeat
                        local entrydir = dir .. "/" .. entry
                        local entrymode = lfs.attributes(entrydir, "mode")

                        if entry:match("^%.") or entrymode ~= "directory" then
                                break
                        end

                        local metamode = lfs.attributes(entrydir  .. "/" .. entry .. "Meta.lua", "mode")
                        if metamode == "file" then
                                applets[no] = {
					applet = entry
				}
				no = no + 1
                        end
                until true end
        until true end

	local result = {
		applets = applets
	}
	return result
end

function hasAppletCommand(self,params)
	local applet = params.applet
	local installed = appletManager:hasApplet(applet)
	local value = {
		value = installed
	}
	return value
end

function getPrefsCommand(self,params)
	local applet = params.applet
	local instance = appletManager:loadApplet(applet)
	local value = instance["getSettings"](instance)
	return value
end

function getPrefCommand(self,params)
	local applet = params.applet
	local pref = params.pref
	local instance = appletManager:loadApplet(applet)
	local value = instance["getSettings"](instance)[pref]
	local result = {
		value = value
	}
	return result
end

function setPrefCommand(self,params)
	local applet = params.applet
	local pref = params.pref
	local value = params.value

	local instance = appletManager:loadApplet(applet)
	instance["getSettings"](instance)[pref] = value
	instance["storeSettings"](instance)
	local result = {
		value = value
	}
	return result
end

function getCommand(self,params)
	local filename = params.file
	if lfs.attributes(filename) then
		log:debug("Getting file: "..tostring(filename))
		local file = io.open(filename,"rb")
		if file then
			local content = file:read("*all")
			local result = {
				filename = filename,
				content = mime.b64(content)
			}
			return result
		end
	end
	return nil
end

function notify_serverDisconnected(self,server, noOfRetries)
	if self.servers then
		local oldSecret = nil
		for key,entry in pairs(self.servers) do
			if tostring(entry) == tostring(server) then
				oldSecret = key
			end
		end
		if oldSecret then
			log:debug("Removing old secret: "..oldSecret)
			self.servers[oldSecret] = nil
		end
	end
end

function notify_serverConnected(self,server)
	server:userRequest(function(chunk,err)
				if err then
					log:warn(err)
				elseif tonumber(chunk.data["_can"]) == 1 then
					local secret = tostring(math.random(1000000))
					if not self.servers then
						self.servers = {}
					end
					self.servers[secret] = server
					log:debug("Registering server "..tostring(server).." as "..secret)
					local supportedCommands = {}
					if self.cmds then
						for cmd,entry in pairs(self.cmds) do
							supportedCommands[cmd] = cmd.."result"
						end
					end
					server:userRequest(function(chunk,err)
							if err then
								log:warn(err)
							end
						end,
						player and player:getId(),
						{'squeezeplayadmin','register',System:getMacAddress(),System:getMachine(),secret,supportedCommands}
					)
					if self.cmds then
						for cmd,entry in pairs(self.cmds) do
							self:subscribeToCommand(server,cmd)
						end
					end
				else
					log:debug("Ignoring "..tostring(server)..", doesn't support squeezeplayadmin commands")
				end
		end,
		nil,
		{'can','squeezeplayadmin','register','?'}
	)
end

function subscribeToCommand(self,server,cmd)
	server.comet:unsubscribe('/slim/squeezeplayadmin.'..cmd)
	server.comet:subscribe(
		'/slim/squeezeplayadmin.'..cmd,
		function(chunk)
			local cmd = string.gsub(chunk.data[1],"^squeezeplayadmin.","")
			log:debug("Got callback for "..cmd)
			local server = chunk.data[2]
			local secret = chunk.data[3]
			local sbs = nil
			if self.servers and self.servers[secret] then
				sbs = self.servers[secret]
				log:debug("Got server for "..secret..": "..tostring(sbs))
			else
				log:debug("Unknown server with secret: "..secret)
			end
			if server == System:getMacAddress() and sbs then
				local handle = chunk.data[4]

				local instance = appletManager:loadApplet(self.cmds[cmd].applet)
				log:debug("Calling "..self.cmds[cmd].applet.."."..self.cmds[cmd].method)
				local result = instance[self.cmds[cmd].method](instance,chunk.data[5])

				if result then
					log:debug("Returning "..cmd.." result in callback to "..tostring(sbs))
					sbs:userRequest(function(chunk,err)
							if err then
								log:warn(err)
							end
						end,
						nil,
						{'squeezeplayadmin',cmd..'result',handle,result}
					)
				end
			elseif not sbs then
				log:debug("Got invalid secret in "..cmd.." command to "..server)
			end
		end,
		nil,
		{'squeezeplayadmin.'..cmd}
	)
end

--[[

=head1 LICENSE

Copyright 2010, Erland Isaksson (erland_i@hotmail.com)
Copyright 2010, Logitech, inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Logitech nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL LOGITECH, INC BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
--]]


