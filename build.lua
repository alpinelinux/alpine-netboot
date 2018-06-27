#!/usr/bin/lua5.3

local yaml = require("lyaml")
local http = require("socket.http")
local pfile = require("pl.file")
local ppath = require("pl.path")
local lustache = require("lustache")

local cf = yaml.load(pfile.read("config.yaml"))
cf.releases = {}
local info = {}

function get_release_info(release, arch)
	local url = ("%s/%s/releases/%s/latest-releases.yaml"):format(
		cf.mirror, release, arch)
	local body, code = http.request(url)
	if not body then error(code) end

	local res = yaml.load(body)
	for k,v in ipairs(res) do
		if v.flavor == "alpine-netboot" then return v end
	end
end

for _,branch in ipairs(cf.branches) do
	for _,arch in ipairs(cf.archs) do
		info = get_release_info(branch, arch)
		if info then
			if ppath.exists(("/var/www/localhost/htdocs/sigs/%s/%s/%s"):format(
				info.branch, info.arch, info.version)) then
				print(("Skipping: %s/%s/%s"):format(
					info.branch, info.arch, info.version))
			else
				info.origin_branch = branch
				print(("Processing: %s/%s/%s"):format(
					info.branch, info.arch, info.version))
				os.execute(("./sign_images.sh \"%s\" \"%s\" \"%s\""):format(
					info.branch, info.arch, info.version))
			end
		end
	end
	if branch == cf.default.branch then 
		cf.default.branch = info.branch
		cf.default.version = info.version
	end
	table.insert(cf.releases, { branch=info.branch, version=info.version })
end

local tpl = pfile.read(cf.tpl)
print("Updating ipxe script: "..cf.ipxe)
pfile.write(cf.ipxe, lustache:render(tpl, cf))
