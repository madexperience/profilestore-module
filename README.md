# ProfileStoreService-Module

데이터 스토어 모듈 Profile Store을 좀 더 쉽게 사용할 수 있도록 만든 모듈입니다.
PostWebHookAsync를 추가하여 버그 및 예기치 않은 오류가 발생 시 웹훅을 이용해 해당 URL로 Post 합니다

Get it here:

* [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore)

## Methods

# [GetData]
```lua
Service.GetData(player: Player)
```
플레이어 데이터 프로필을 가져옵니다 (Default Max Try 10)

```lua
function Service.GetData(player: Player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		PostWebHookAsync(player,"잘못된 경로로 데이터스토어 접근 (확인 요함)")
		return nil
	end
	
	local ST = tick()
	local MT = 10 --Max Time
	
	while tick() - ST < MT do
		local profile = Profiles[player]
		if profile and profile:IsActive() then
			return profile.Data
		end
		task.wait(.2)
	end
	
	PostWebHookAsync(player,"데이터 로드 대기 시간 초과 / Session Ended Please Rejoin")
	return nil
end
```
##

# [UpdateData]
```lua
Service.UpdateData(player: Player, key: string, value: any?)
```
변경된 데이터를 플레이어 데이터 프로필에 덮어씌웁니다

```lua
function Service.UpdateData(player: Player, key: string, value: any?)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		PostWebHookAsync(player,"잘못된 경로로 데이터스토어 접근 (확인 요함) [player]")
		return
	end
	
	if typeof(key) ~= "string" then
		PostWebHookAsync(player,"잘못된 경로로 데이터스토어 접근 (확인 요함) [Key]")
		return
	end

	local profile = Profiles[player]
	
	if profile and profile:IsActive() then
		if not profile.Data[key] then
			PostWebHookAsync(player,"데이터스토어 업데이트 실패 (잘못된 데이터스토어 Key)")
			return
		else
			profile.Data[key] = value
		end
	else
		PostWebHookAsync(player,"데이터스토어 업데이트 실패 (Session Ended)")
		return
	end
end

Service.UpdateData(player, key, value)
```
##


# [InsertData]
```lua
Service.InsertData(player: Player, key: string, category: string, amount : number?)
```
딕셔너리 형태의 테이블 (인벤토리,플레이어State)에 키를 대조해 number 타입의 값(amount)을 삽입합니다.

```lua
function Service.InsertData(player: Player, key: string, category: string, amount : number?)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		PostWebHookAsync(player,"잘못된 경로로 데이터스토어 접근 (확인 요함) [player]")
		return
	end
	
	if typeof(category) ~= "string" then
		PostWebHookAsync(player,"잘못된 경로로 데이터스토어 접근 (확인 요함) [key]")
		return
	end

	local profile = Profiles[player]
	if not (profile and profile:IsActive()) then
		PostWebHookAsync(player,"데이터스토어 접근 실패 (Session Ended)")
		return
	end

	local inventory = profile.Data[category]
	if typeof(inventory) ~= "table" then
		PostWebHookAsync(player, "Inventory 테이블이 존재하지 않음 (손상 또는 악성 접근 가능성)" , ": " , inventory)
		return
	end

	inventory[key] = (inventory[key] or 0) + (amount or 1)
end

Service.InsertData(player, key, category, amount)
```
##


# [RemoveData]
```lua
Service.RemoveData(player: Player, key: string, category: string, amount: number?)
```
딕셔너리 형태의 테이블에 키를 대조해 amount(값) 만큼 뺍니다

```lua
function Service.RemoveData(player: Player , category: string , key: string , amount : number?)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		PostWebHookAsync(player,"잘못된 경로로 데이터스토어 접근 (확인 요함) [player]")
		return
	end
	if typeof(category) ~= "string" then
		PostWebHookAsync(player,"잘못된 경로로 데이터스토어 접근 (확인 요함) [category]")
		return
	end

	--Get profile from table
	local profile = Profiles[player]
	if not (profile and profile:IsActive()) then
		PostWebHookAsync(player,"데이터스토어 접근 실패 (Session End)")
		return
	end

	--Get inventroy from profile data
	local inventory = profile.Data[category]
	if typeof(inventory) ~= "table" then
		PostWebHookAsync(player, "Inventory 테이블이 존재하지 않음 (손상 또는 악성 접근 가능성)" , ": " , inventory)
		return
	end

	--get current amount of inventory[value]
	local currentAmount = inventory[key]
	if typeof(currentAmount) ~= "number" or currentAmount <= 0 then
		PostWebHookAsync(player, `아이템 제거 실패: 존재하지 않거나 개수 없음 → {category}[{key}]`)
		return
	end

	--Check if substract amount more than currentAmount
	if amount > currentAmount then
		PostWebHookAsync(player,`아이템 존재개수보다 뺄려는 수량이 더 많음 / 현재 개수: {currentAmount} / Remove Count :{amount}`)
		return
	end

	--substract from inventory[value]
	inventory[key] = currentAmount - amount

	--nil if inventory[value] less than 0
	if inventory[key] <= 0 then
		inventory[key] = nil
	end
end

Service.RemoveData(player, key, category, amount)
```
##


# [ClearData]
```lua
Service:ClearData(player: Player, key: string)
```
플레이어 데이터에 키를 대조해 해당 키 값을 기본 템플릿으로 초기화 시킵니다

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

# [ClearAllData]
```lua
Service.ClearAllData(player: Player)
```
플레이어 데이터를 기본 템플릿값으로 초기화 시킵니다

```lua
function Service.ClearAllData(player: Player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		error("첫번째 인자(player)는 무조건 Player 개체여야 합니다.")
	end

	local profile = Profiles[player]
	if not (profile and profile:IsActive()) then
		PostWebHookAsync(player,"데이터스토어 접근 실패 (Session End)")
		return
	end

	for key, defaultValue in pairs(DEFAULT_PLAYER_DATA) do
		profile.Data[key] = defaultValue
	end

	warn(player.Name," 의 데이터가 전체 리셋 되었습니다.")
end
Service.ClearAllData(player)
```
##

