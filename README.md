# ProfileStoreService-Module

데이터 스토어 모듈 Profile Store을 좀 더 쉽게 사용할 수 있도록 만든 모듈입니다. 

Get it here:

* [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore)

## Methods

# [GetData]
```lua
Service:GetData(player: Player)
```
플레이어 데이터 프로필을 가져옵니다

```lua
function Service:GetData<T>(player: Player): G_Types.GetData<T>
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		error("GetData() 인자는 반드시 Player 개체 이어야 합니다.")
	end

	local profile = Profiles[player]
	if not profile then return nil end

	return profile.Data
end

local myData = Service:GetData()
print(myData) --플레이어 데이터 출력
```
##

# [UpdateData]
```lua
Service:UpdateData(player: Player, key: string, amount: any?)
```
변경된 데이터를 플레이어 데이터 프로필에 덮어씌웁니다

```lua
function Service:UpdateData(player: Player, key: string, amount: any?): G_Types.UpdateData
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		error("첫번째 인자(player)는 무조건 플레이어 개체가 들어가야합니다.")
	end
	if typeof(key) ~= "string" then
		error("두번째 인자(key)는 무조건 string 타입 이어야 합니다.")
	end

	local data = Service:GetData(player)
	if not data then return end

	local value = data[key]

	if typeof(value) == typeof(amount) then
		data[key] = amount
		print("Key ",key," Updated",data[key])
	else		
		error("Wrong type match. Are you forgot to set amount and key as same type?")
	end
end

Service:UpdateData(player, key, amount)
```
##


# [SaveData]
```lua
Service:ClearData(player: Player, key: string)
```
플레이어 데이터 프로필을 기본 템플릿으로 초기화 시킵니다

```lua
function Service:ClearData(player: Player, key: string): G_Types.ClearData
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		error("첫번째 인자(player)는 무조건 Player 개체여야 합니다.")
	end
	if typeof(key) ~= "string" then
		error("두번째 인자(key)는 반드시 string 타입이어야 합니다.")
	end

	local data = Service:GetData(player)
	if not data then return end

	if DEFAULT_PLAYER_DATA[key] ~= nil then
		data[key] = DEFAULT_PLAYER_DATA[key]
		print(player.Name .. "'s " .. key .. " reset to default: " .. tostring(data[key]))
	else
		warn("Key '" .. key .. "' does not exist in the default template.")
	end
end
```
