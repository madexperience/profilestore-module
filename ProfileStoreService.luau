--Made by Mad_Experience 24.12.30 // 

-- 사용법
-- .Init() <-- 초기설정
-- .GetData(player) <--- 데이터 가져오기
-- .SaveData(player) <--- 데이터 저장(거래 등 중요할때만 호출! 호출비용 UpdateAsync() 1회)
-- .UpdateData(player: Player , key: string , [value: number | string]: string, number, boolean) <--- value 업데이트
-- .InsertData(player: Player , key: string , category : string , amount : number) <-- 딕셔너리 형태의 테이블(인벤토리 등) value 삽입
-- .RemoveData(player: Player , key: string , category : string , amount : number) <-- 딕셔너리 형태의 테이블(인벤토리 등) value 제거
-- .ClearData(player,key) <--- 데이터 키 찾아서 리셋
-- .ClearAllData(player) <-- 데이터 리셋

--	**/추가예정/**
-- :RollbackData(player,time) <- 플레이어 데이터 롤백기능 // time(os.clock Server Time)
-- :RollbackServer(time) <- 서버 롤백
---------------------------------------------------------------
---------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local ProfileStore = require(script.ProfileStore)

---------------------------------------------------------------
------------------/ Templates /--------------------------------
---------------------------------------------------------------

local DATA_STORE_KEY = "Newdatabase" --데이터 스토어 키 생성
local TEST_DATA_STORE_KEY = "Test_Newdatabase" --스튜디오 전용 데이터 키 생성

--Webhook URL
local WEBHOOK_URL = ""

---------------------------------------------------------------
----------------------/ Types /--------------------------------
---------------------------------------------------------------

local DEFAULT_PLAYER_DATA = require(script.Template) --Template 경로 설정
export type DEFAULT_PLAYER_DATA = typeof(DEFAULT_PLAYER_DATA)

export type DataManagerType = {
	Init : () -> (),
	GetData : (player : Player) -> (),
	SaveData : (player : Player) -> (),
	InsertData : (player: Player, key: string, value: any?) -> (),
	RemoveData : (player: Player, key: string, value: any?) -> (),
	ClearData : (player: Player, key: string) -> (),
	ClearAllData : (player: Player) -> (),
}

---------------------------------------------------------------
----------------------/ Main /---------------------------------
---------------------------------------------------------------

--Check if run on client
if RunService:IsStudio() then
	DATA_STORE_KEY = TEST_DATA_STORE_KEY
end

local PlayerProfile = ProfileStore.New(DATA_STORE_KEY, DEFAULT_PLAYER_DATA)
local Profiles: {[player]: typeof(PlayerProfile:StartSessionAsync())} = {}

--Add leaderstats---------------------------------------------------------------
local function InitLeaderstats(player : Player , profile : typeof(PlayerProfile:StartSessionAsync()))
	
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local level = Instance.new("NumberValue")
	level.Name = "Level"
	level.Value = profile.Data.Level
	level.Parent = leaderstats
	
	local coin = Instance.new("NumberValue")
	coin.Name = "Coin"
	coin.Value = profile.Data.Coin
	coin.Parent = leaderstats
	
end

--Return UTC Time to KST Time---------------------------------------------------------------
local function KSTTimeStamp()
	local utc = os.time(os.date("!*t"))
	local kst = utc + (9 * 60 * 60)
	return os.date("%Y-%m-%d %H:%M:%S", kst)
end

--Post Webhook---------------------------------------------------------------
local function PostWebHookAsync(player: Player, reason: string)
	local data = {
		["embeds"] = {
			{
				["author"] = {
					["name"] = player.Name,
					["icon_url"] = "https://www.roblox.com/Thumbs/Avatar.ashx?x=100&y=100&username=" .. player.Name
				},
				["description"] = reason .. " / KST TIME : " .. KSTTimeStamp(),
				["color"] = tonumber(0xFFFAFA),
				["fields"] = {
					{
						["name"] = "Account Age:",
						["value"] = tostring(player.AccountAge),
						["inline"] = true
					},
					{
						["name"] = "User ID:",
						["value"] = tostring(player.UserId),
						["inline"] = true
					}
				}
			}
		}
	}

	local finalData = HttpService:JSONEncode(data)
	
	local success, result = pcall(function()
		HttpService:PostAsync(WEBHOOK_URL, finalData)
	end)

	if not success then
		warn("[WEBHOOK ERROR]:", result)
	end
end

--Load profile---------------------------------------------------------------
local function ProfileLoad(player : Player)
	
	--start session when player joined
	local profile = PlayerProfile:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	--check if it is right session
	if profile == nil then
		return player:Kick("Data Error Occured. Please Rejoin")
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	--session ended callback function
	profile.OnSessionEnd:Connect(function()
		Profiles[player] = nil
		player:Kick("Profile Session Ended. Please Rejoin")
	end)
	
	--check if player is valid member of players
	local isInGame = player.Parent == Players
	if isInGame then
		Profiles[player] = profile
		InitLeaderstats(player,profile)
	else
		profile:EndSession()
	end

	warn("===== 플레이어 ",player.Name,"의 프로파일 로드 완료",Profiles[player])
end

--Remove profile---------------------------------------------------------------
local function RemoveProfile(player : Player)
	local profile = Profiles[player]
	if not profile then return end
	profile:EndSession()
	Profiles[player] = nil
end

------------------------------------------------------------
----------------/ Global Functions /------------------------
------------------------------------------------------------

local Service = {}

--Initializing DataManager---------------------------------------------------------------
function Service.Init()
	for _, player in Players:GetChildren() do
		task.spawn(ProfileLoad, player)
	end

	Players.PlayerAdded:Connect(ProfileLoad)
	Players.PlayerRemoving:Connect(RemoveProfile)
	
	if RunService:IsStudio() then
		warn("===================== 현재 데이터 스토어 키 : ",DATA_STORE_KEY)	
	end
end

--Get player profile---------------------------------------------------------------
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

--Save player data (거래시스템용 자주사용x)---------------------------------------------------------------
function Service.SaveData(player : Players)
	local profile = Profiles[player]
	if profile and profile:IsActive() then
		profile:Save()
	else
		PostWebHookAsync(player,"데이터스토어 저장 실패")
		return
	end
end

--Update player data (only for Number, Bool, String)---------------------------------------------------------------
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

--Insert player data (only for type of table)---------------------------------------------------------------
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

--Remove player data (only for type of table)---------------------------------------------------------------
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

--Clear player data (기존 플레이어 데이터 초기화 사용시 주의 요함)---------------------------------------------------------------
function Service.ClearData(player: Player, key: string)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		PostWebHookAsync(player,"잘못된 경로로 데이터스토어 접근 (확인 요함) [player]")
		return
	end

	if typeof(key) ~= "string" then
		PostWebHookAsync(player,"잘못된 경로로 데이터스토어 접근 (확인 요함) [Key]")
		return
	end

	--Get profile from table
	local profile = Profiles[player]
	if not (profile and profile:IsActive()) then
		PostWebHookAsync(player,"데이터스토어 접근 실패 (Session End)")
		return
	end

	if DEFAULT_PLAYER_DATA[key] ~= nil then
		profile.Data[key] = DEFAULT_PLAYER_DATA[key]
	else
		PostWebHookAsync(player,"템플릿에 해당 키가 존재하지 않음 : ",key)
		return
	end
end

--Clear all player data(플레이어 데이터 전체 초기화 사용시 주의 요함)---------------------------------------------------------------
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


return Service