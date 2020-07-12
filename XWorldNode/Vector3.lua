
local acos	= math.acos
local sqrt 	= math.sqrt
local max 	= math.max
local min 	= math.min
local clamp = math.clamp
local cos	= math.cos
local sin	= math.sin
local abs	= math.abs
local sign	= math.sign
local setmetatable = setmetatable
local rawset = rawset
local rawget = rawget

local rad2Deg = math.rad2Deg
local deg2Rad = math.deg2Rad

Vector3 = 
{	
	class = "Vector3",
}

local fields = {}

setmetatable(Vector3, Vector3)

Vector3.__index = function(t,k)
	local var = rawget(Vector3, k)
	
	if var == nil then							
		var = rawget(fields, k)
		
		if var ~= nil then
			return var(t)				
		end		
	end
	
	return var
end

Vector3.__call = function(t,x,y,z)
	return Vector3.New(x,y,z)
end

--循环使用
local pools = {}
local poolsLen = 0
local lastPoolVec = nil
local function Vector3GetPool()
	if lastPoolVec then
		local vec = lastPoolVec
		lastPoolVec = nil
		return vec
	end
	if poolsLen>0 then
		local vec = pools[poolsLen]
		pools[poolsLen] = nil
		poolsLen = poolsLen-1
		return vec
	end
	return nil
end
function Vector3_pool(vec)
	if not lastPoolVec then
		lastPoolVec = vec
		return
	end
	if vec then
		if poolsLen>=16 then	--防止泄漏
			return
		end
		poolsLen = poolsLen+1
		pools[poolsLen] = vec
	end
end

function Vector3.New(x, y, z)
	local p = Vector3GetPool()
	if p then
		--print("--Vector3--use pool---")
		p.x=x or 0
		p.y=y or 0
		p.z=z or 0
		return p
	end
	--print("----Vector3.New----")
	local v = {x = x or 0, y = y or 0, z = z or 0}		
	setmetatable(v, Vector3)		
	return v
end

function Vector3.New_Csharp(x, y, z)
	return Vector3.New(x, y, z)
end
	
function Vector3:Set(x,y,z)
	if self==nil then
		return
	end
	self.x = x or 0
	self.y = y or 0
	self.z = z or 0
end

function Vector3:Get()	
	if self==nil then
		return 0, 0, 0
	end
	return self.x, self.y, self.z	
end

function Vector3:Clone()
	return Vector3.New(self.x, self.y, self.z)
end

function Vector3.Distance(va, vb)
	return sqrt((va.x - vb.x)^2 + (va.y - vb.y)^2 + (va.z - vb.z)^2)
end

function Vector3.Dot(lhs, rhs)
	return (((lhs.x * rhs.x) + (lhs.y * rhs.y)) + (lhs.z * rhs.z))
end

function Vector3.Lerp(from, to, t)	
	t = clamp(t, 0, 1)
	return Vector3.New(from.x + ((to.x - from.x) * t), from.y + ((to.y - from.y) * t), from.z + ((to.z - from.z) * t))
end

function Vector3:Magnitude()
	return sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function Vector3.Max(lhs, rhs)
	return Vector3.New(max(lhs.x, rhs.x), max(lhs.y, rhs.y), max(lhs.z, rhs.z))
end

function Vector3.Min(lhs, rhs)
	return Vector3.New(min(lhs.x, rhs.x), min(lhs.y, rhs.y), min(lhs.z, rhs.z))
end

function Vector3:Normalize()
	local v = self:Clone()
	return v:SetNormalize()
end

function Vector3:SetNormalize()
	local num = self:Magnitude()	
	
	if num == 1 then
		return self
    elseif num > 1e-5 then    
        self:Div(num)
    else    
		self:Set(0,0,0)
	end 

	return self
end
	
function Vector3:SqrMagnitude()
	return self.x * self.x + self.y * self.y + self.z * self.z
end

local dot = Vector3.Dot

function Vector3.Angle(from, to)
	return acos(clamp(dot(from:Normalize(), to:Normalize()), -1, 1)) * rad2Deg
end

function Vector3:ClampMagnitude(maxLength)	
	if self:SqrMagnitude() > (maxLength * maxLength) then    
		self:SetNormalize()
		self:Mul(maxLength)        
    end
	
    return self
end


function Vector3.OrthoNormalize(va, vb, vc)	
	va:SetNormalize()
	vb:Sub(vb:Project(va))
	vb:SetNormalize()
	
	if vc == nil then
		return va, vb
	end
	
	vc:Sub(vc:Project(va))
	vc:Sub(vc:Project(vb))
	vc:SetNormalize()		
	return va, vb, vc
end

function Vector3.RotateTowards2(from, to, maxRadiansDelta, maxMagnitudeDelta)	
	local v2 	= to:Clone()
	local v1 	= from:Clone()
	local len2 	= to:Magnitude()
	local len1 	= from:Magnitude()	
	v2:Div(len2)
	v1:Div(len1)
	
	local dota	= dot(v1, v2)
	local angle = acos(dota)			
	local theta = min(angle, maxRadiansDelta)	
	local len	= 0
	
	if len1 < len2 then
		len = min(len2, len1 + maxMagnitudeDelta)
	elseif len1 == len2 then
		len = len1
	else
		len = max(len2, len1 - maxMagnitudeDelta)
	end
						    
    v2:Sub(v1 * dota)
    v2:SetNormalize()     
	v2:Mul(sin(theta))
	v1:Mul(cos(theta))
	v2:Add(v1)
	v2:SetNormalize()
	v2:Mul(len)
	return v2	
end

function Vector3.RotateTowards1(from, to, maxRadiansDelta, maxMagnitudeDelta)	
	local omega, sinom, scale0, scale1, len, theta
	local v2 	= to:Clone()
	local v1 	= from:Clone()
	local len2 	= to:Magnitude()
	local len1 	= from:Magnitude()	
	v2:Div(len2)
	v1:Div(len1)
	
	local cosom = dot(v1, v2)
	
	if len1 < len2 then
		len = min(len2, len1 + maxMagnitudeDelta)	
	elseif len1 == len2 then
		len = len1
	else
		len = max(len2, len1 - maxMagnitudeDelta)
	end 	
	
	if 1 - cosom > 1e-6 then	
		omega 	= acos(cosom)
		theta 	= min(omega, maxRadiansDelta)		
		sinom 	= sin(omega)
		scale0 	= sin(omega - theta) / sinom
		scale1 	= sin(theta) / sinom
		
		v1:Mul(scale0)
		v2:Mul(scale1)
		v2:Add(v1)
		v2:Mul(len)
		return v2
	else 		
		v1:Mul(len)
		return v1
	end			
end

--[[--
此函数开销太大，请使用Vector3.MoveTowardsEachDir代替
]]	
function Vector3.MoveTowards(current, target, maxDistanceDelta)	
	local delta = target - current	
    local sqrDelta = delta:SqrMagnitude()
	local sqrDistance = maxDistanceDelta * maxDistanceDelta
	
    if sqrDelta > sqrDistance then    
		local magnitude = sqrt(sqrDelta)
		
		if magnitude > 1e-6 then
			delta:Mul(maxDistanceDelta / magnitude)
			delta:Add(current)
			return delta
		else
			return current:Clone()
		end
    end
	
    return target:Clone()
end

--[[--
 current 	:当前的点
 target  	:目标点
 speedX  	:X方向上的移动速度
 speedY  	:Y方向上的移动速度
 speedZ  	:Z方向上的移动速度
 moveTime	:移动的时间
]]
function Vector3.MoveTowardsEachDir(current, target, speedX, speedY, speedZ, moveTime)
	local disX = target.x - current.x
	local disY = target.y - current.y
	local disZ = target.z - current.z
	local moveX = speedX * moveTime
	local moveY = speedY * moveTime
	local moveZ = speedZ * moveTime

	if disX > 0 then
		moveX = disX > moveX and moveX or disX
	elseif disX < 0 then
		moveX = disX < moveX and moveX or disX
	else
		moveX = 0
	end
	
	if disY > 0 then
		moveY = disY > moveY and moveY or disY
	elseif disY < 0 then
		moveY = disY < moveY and moveY or disY
	else
		moveY = 0
	end

	if disZ > 0 then
		moveZ = disZ > moveZ and moveZ or disZ
	elseif disZ < 0 then
		moveZ = disZ < moveZ and moveZ or disZ
	else
		moveZ = 0
	end
	return current.x + moveX, current.y + moveY, current.z + moveZ
end

function ClampedMove(lhs, rhs, clampedDelta)
	local delta = rhs - lhs
	
	if delta > 0 then
		return lhs + min(delta, clampedDelta)
	else
		return lhs - min(-delta, clampedDelta)
	end
end

local overSqrt2 = 0.7071067811865475244008443621048490

local function OrthoNormalVector(vec)
	local res = Vector3.New()
	
	if abs(vec.z) > overSqrt2 then			
		local a = vec.y * vec.y + vec.z * vec.z
		local k = 1 / sqrt (a)
		res.x = 0
		res.y = -vec.z * k
		res.z = vec.y * k
	else			
		local a = vec.x * vec.x + vec.y * vec.y
		local k = 1 / sqrt (a)
		res.x = -vec.y * k
		res.y = vec.x * k
		res.z = 0
	end
	
	return res
end

function Vector3.RotateTowards(current, target, maxRadiansDelta, maxMagnitudeDelta)
	local len1 = current:Magnitude()
	local len2 = target:Magnitude()
	
	if len1 > 1e-6 and len2 > 1e-6 then	
		local from = current / len1
		local to = target / len2		
		local cosom = dot(from, to)
				
		if cosom > 1 - 1e-6 then		
			return Vector3.MoveTowards (current, target, maxMagnitudeDelta)		
		elseif cosom < -1 + 1e-6 then		
			local axis = OrthoNormalVector(from)						
			local q = Quaternion.AngleAxis(maxRadiansDelta * rad2Deg, axis)	
			local rotated = q:MulVec3(from)
			local delta = ClampedMove(len1, len2, maxMagnitudeDelta)
			rotated:Mul(delta)
			return rotated
		else		
			local angle = acos(cosom)
			local axis = Vector3.Cross(from, to)
			axis:SetNormalize ()
			local q = Quaternion.AngleAxis(min(maxRadiansDelta, angle) * rad2Deg, axis)			
			local rotated = q:MulVec3(from)
			local delta = ClampedMove(len1, len2, maxMagnitudeDelta)
			rotated:Mul(delta)
			return rotated
		end
	end
		
	return Vector3.MoveTowards(current, target, maxMagnitudeDelta)
end
	
function Vector3.SmoothDamp(current, target, currentVelocity, smoothTime)
	local maxSpeed = math.huge
	local deltaTime = Time.deltaTime
    smoothTime = max(0.0001, smoothTime)
    local num = 2 / smoothTime
    local num2 = num * deltaTime
    local num3 = 1 / (((1 + num2) + ((0.48 * num2) * num2)) + (((0.235 * num2) * num2) * num2))    
    local vector2 = target:Clone()
    local maxLength = maxSpeed * smoothTime
	local vector = current - target
    vector:ClampMagnitude(maxLength)
    target = current - vector
    local vec3 = (currentVelocity + (vector * num)) * deltaTime
    currentVelocity = (currentVelocity - (vec3 * num)) * num3
    local vector4 = target + (vector + vec3) * num3	
	
    if Vector3.Dot(vector2 - current, vector4 - vector2) > 0 then    
        vector4 = vector2
        currentVelocity:Set(0,0,0)
    end
	
    return vector4, currentVelocity
end	
	
function Vector3.Scale(a, b)
	local v = a:Clone()
	return v:SetScale(b)
end

function Vector3:SetScale(b)
	self.x = self.x * b.x
	self.y = self.y * b.y
	self.z = self.z * b.z	
	return self
end
	
function Vector3.Cross(lhs, rhs)
	local x = lhs.y * rhs.z - lhs.z * rhs.y
	local y = lhs.z * rhs.x - lhs.x * rhs.z
	local z = lhs.x * rhs.y - lhs.y * rhs.x
	return Vector3.New(x,y,z)	
end
	
function Vector3:Equals(other)
	return self.x == other.x and self.y == other.y and self.z == other.z
end
		
function Vector3.Reflect(inDirection, inNormal)
	local num = -2 * dot(inNormal, inDirection)
	inNormal = inNormal * num
	inNormal:Add(inDirection)
	return inNormal
end

	
function Vector3.Project(vector, onNormal)
	local num = onNormal:SqrMagnitude()
	
	if num < 1.175494e-38 then	
		return Vector3.New(0,0,0)
	end
	
	local num2 = dot(vector, onNormal)
	local v3 = onNormal:Clone()
	v3:Mul(num2/num)	
	return v3
end
	
function Vector3.ProjectOnPlane(vector, planeNormal)
	local v3 = Vector3.Project(vector, planeNormal)
	v3:Mul(-1)
	v3:Add(vector)
	return v3
end		

function Vector3.Slerp2(from, to, t)		
	if t <= 0 then
		return from:Clone()
	elseif t >= 1 then
		return to:Clone()
	end
	
	local v2 	= to:Clone()
	local v1 	= from:Clone()
	local len2 	= to:Magnitude()
	local len1 	= from:Magnitude()	
	v2:Div(len2)
	v1:Div(len1)
	
	local omega = dot(v1, v2) 	
	local len 	= (len2 - len1) * t + len1    		
    local theta = acos(omega) * t
	
    v2:Sub(v1 * omega)
    v2:SetNormalize()     
	v2:Mul(sin(theta))
	v1:Mul(cos(theta))
	v2:Add(v1)
	v2:SetNormalize()
	v2:Mul(len)
    return v2	
end

function Vector3.Slerp(from, to, t)
	local omega, sinom, scale0, scale1

	if t <= 0 then		
		return from:Clone()
	elseif t >= 1 then		
		return to:Clone()
	end
	
	local v2 	= to:Clone()
	local v1 	= from:Clone()
	local len2 	= to:Magnitude()
	local len1 	= from:Magnitude()	
	v2:Div(len2)
	v1:Div(len1)

	local len 	= (len2 - len1) * t + len1
	local cosom = dot(v1, v2)
	
	if 1 - cosom > 1e-6 then
		omega 	= acos(cosom)
		sinom 	= sin(omega)
		scale0 	= sin((1 - t) * omega) / sinom
		scale1 	= sin(t * omega) / sinom
	else 
		scale0 = 1 - t
		scale1 = t
	end

	v1:Mul(scale0)
	v2:Mul(scale1)
	v2:Add(v1)
	v2:Mul(len)
	return v2
end


function Vector3:Mul(q)
	if type(q) == "number" then
		self.x = self.x * q
		self.y = self.y * q
		self.z = self.z * q
	else
		self:MulQuat(q)
	end
	
	return self
end

function Vector3:Div(d)
	self.x = self.x / d
	self.y = self.y / d
	self.z = self.z / d
	
	return self
end

function Vector3:Add(vb)
	self.x = self.x + vb.x
	self.y = self.y + vb.y
	self.z = self.z + vb.z
	
	return self
end

function Vector3:Sub(vb)
	self.x = self.x - vb.x
	self.y = self.y - vb.y
	self.z = self.z - vb.z
	
	return self
end

function Vector3:ToString()
	Debug.Log("  posX "..self.x.." posY "..self.y.."  posZ "..self.z)
end

function Vector3:MulQuat(quat)	   
	local num 	= quat.x * 2
	local num2 	= quat.y * 2
	local num3 	= quat.z * 2
	local num4 	= quat.x * num
	local num5 	= quat.y * num2
	local num6 	= quat.z * num3
	local num7 	= quat.x * num2
	local num8 	= quat.x * num3
	local num9 	= quat.y * num3
	local num10 = quat.w * num
	local num11 = quat.w * num2
	local num12 = quat.w * num3
	
	local x = (((1 - (num5 + num6)) * self.x) + ((num7 - num12) * self.y)) + ((num8 + num11) * self.z)
	local y = (((num7 + num12) * self.x) + ((1 - (num4 + num6)) * self.y)) + ((num9 - num10) * self.z)
	local z = (((num8 - num11) * self.x) + ((num9 + num10) * self.y)) + ((1 - (num4 + num5)) * self.z)
	
	self:Set(x, y, z)	
	return self
end

function Vector3.AngleAroundAxis (from, to, axis)	 	 
	from = from - Vector3.Project(from, axis)
	to = to - Vector3.Project(to, axis) 	    
	local angle = Vector3.Angle (from, to)	   	    
	return angle * (Vector3.Dot (axis, Vector3.Cross (from, to)) < 0 and -1 or 1)
end


Vector3.__tostring = function(self)
	if not self.x then
		self.x=0
	end
	if not self.y then
		self.y=0
	end
	if not self.z then
		self.z=0
	end
	return "["..self.x..","..self.y..","..self.z.."]"
end

Vector3.__div = function(va, d)
	return Vector3.New(va.x / d, va.y / d, va.z / d)
end

Vector3.__mul = function(va, d)
	if type(d) == "number" then
		return Vector3.New(va.x * d, va.y * d, va.z * d)
	else
		local vec = va:Clone()
		vec:MulQuat(d)
		return vec
	end	
end

Vector3.__add = function(va, vb)
	return Vector3.New(va.x + vb.x, va.y + vb.y, va.z + vb.z)
end

Vector3.__sub = function(va, vb)
	return Vector3.New(va.x - vb.x, va.y - vb.y, va.z - vb.z)
end

Vector3.__unm = function(va)
	return Vector3.New(-va.x, -va.y, -va.z)
end

Vector3.__eq = function(a,b)
	local v = a - b
	local delta = v:SqrMagnitude()
	return delta < 1e-10
end


local up=Vector3.New(0,1,0)
fields.up = function()
	up.x=0
	up.y=1
	up.z=0
	return up
end

local down=Vector3.New(0,-1,0)
fields.down = function()
	down.x=0
	down.y=-1
	down.z=0
	return down
end

local right=Vector3.New(1,0,0)
fields.right = function()
	right.x=1
	right.y=0
	right.z=0
	return right
end

local left=Vector3.New(-1,0,0)
fields.left = function()
	left.x=-1
	left.y=0
	left.z=0
	return left
end

local forward=Vector3.New(0,0,1)
fields.forward = function()
	forward.x=0
	forward.y=0
	forward.z=1
	return forward
end

local back=Vector3.New(0,0,-1)
fields.back = function()
	back.x=0
	back.y=0
	back.z=-1
	return back
end

local zero=Vector3.New(0,0,0)
fields.zero = function() 
	zero.x=0
	zero.y=0
	zero.z=0
	return zero 
end

local one=Vector3.New(1,1,1)
fields.one = function()
	one.x=1
	one.y=1
	one.z=1
	return one 
end

fields.magnitude 	= Vector3.Magnitude
fields.normalized 	= Vector3.Normalize
fields.sqrMagnitude = Vector3.SqrMagnitude

--减少不必要的new
local temp=Vector3.New(0, 0, 0)
function Vector3_temp(x, y, z)
	temp.x=x or 0
	temp.y=y or 0
	temp.z=z or 0
	return temp
end

--[[
判断大于距离
]]
function Vector3.CompareGreaterDistance(va,vb,dis)
	return (va.x - vb.x)^2 + (va.z - vb.z)^2 > dis ^ 2
end

--[[
判断小于距离
]]
function Vector3.CompareLessDistance(va,vb,dis)
	return (va.x - vb.x)^2 + (va.z - vb.z)^2 < dis ^ 2
end

function Vector3.NewFromTable(tb)
	return Vector3.New(tb[1], tb[2], tb[3])
end