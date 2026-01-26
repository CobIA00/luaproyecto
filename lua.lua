--// DeepSpy v2  (indetectable layer - 0xDev)
--// Hook total: RemoteEvent, RemoteFunction, BindableEvent, BindableFunction, & network step
local core	= game:GetService("CoreGui")
local rs	= game:GetService("RunService")
local rep	= game:GetService("ReplicatedStorage")
local http	= game:GetService("HttpService") -- solo para serializar prints
local player= game:GetService("Players").LocalPlayer

local stored  = {}
local Block, Spoof = {}, {}

--// 1.  Closure sin nombre + constante nil para evitar detección por source
local function protect(fn)
	return (function(...) return fn(...) end)
end

--// 2.  Bytecode wrap: reemplazamos la función original por una clonada con newcclosure
local function wrapFunction(real)
	return protect(function(self, ...)
		local args = {...}
		local meta = debug.getmetatable(self)
		local name = (self.Name or "???").."@"..self:GetFullName()

		--// 3.  Logging profundo (serializado)
		local safe = {}
		for i = 1, select("#", ...) do
			local v = args[i]
			local t = typeof(v)
			if t == "table" then
				safe[i] = http:JSONEncode(v) -- serialización superficial segura
			else
				safe[i] = tostring(v)
			end
		end
		print(string.format("[DEEP] %s  |  Args:%s", name, table.concat(safe,", ")))

		--// 4.  Block / Spoof layer
		if Block[self] then return end
		if Spoof[self] then return table.unpack(Spoof[self]) end

		--// 5.  Ejecutamos el original a través de una nueva closure
		return real(self, ...)
	end)
end

--// 6.  Metatable hooking: sobrescribimos __namecall (método interno de Luau)
local realNamecall
realNamecall = hookmetamethod(game, "__namecall", protect(function(self, ...)
	local method = getnamecallmethod()
	if (method == "FireServer" or method == "InvokeServer") and self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
		return wrapFunction(realNamecall)(self, ...)
	end
	return realNamecall(self, ...)
end))

--// 7.  Hook adicional para Bindables (algunos juegos usan bindables internas)
local function hookBindable(b)
	if stored[b] then return end
	stored[b] = true
	if b:IsA("BindableEvent") then
		local old = b.Fire
		b.Fire = wrapFunction(old)
	elseif b:IsA("BindableFunction") then
		local old = b.Invoke
		b.Invoke = wrapFunction(old)
	end
end

--// 8.  Escaneo recursivo con detección de nuevas instancias
local function deepScan(root)
	for _,v in ipairs(root:GetDescendants()) do
		if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
			-- ya están cubiertas por __namecall
		elseif v:IsA("BindableEvent") or v:IsA("BindableFunction") then
			hookBindable(v)
		end
	end
end
deepScan(rep)
rep.DescendantAdded:Connect(function(c)
	if c:IsA("BindableEvent") or c:IsA("BindableFunction") then
		hookBindable(c)
	end
end)

--// 9.  API pública (usa esto para bloquear/spoof en caliente)
getgenv().DeepSpy = {
	block  = function(remote) Block[remote] = true end,
	unblock= function(remote) Block[remote] = nil  end,
	spoof  = function(remote, ...) Spoof[remote] = {...} end,
	unspoof= function(remote) Spoof[remote] = nil end
}

print("[DeepSpy] Hooking profundo activo. Usa DeepSpy.block(remote) ó DeepSpy.spoof(remote, ...)")
