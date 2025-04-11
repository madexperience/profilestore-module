--Made by Mad_Experience 24.12.30 // 

-- 사용법
-- :GetData(player) <--- 프로파일 데이터 가져오기
-- :UpdateData(player,key,amount) <--- 데이터 업데이트 // player(플레이어), key(키), amount(추가할 양)
-- :ClearData(player,key) <--- 데이터 키 찾아서 리셋
-- :ClearAllData(player) <-- 데이터 리셋

--	**/추가예정/**
-- :RollbackData(player,time) <- 플레이어 데이터 롤백기능 // time(os.clock Server Time)
-- :RollbackServer(time) <- 서버 롤백
---------------------------------------------------------------
---------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileStore = require(script.ProfileStore)
---------------------------------------------------------------
------------------/ 템플릿 설정 /------------------------------
---------------------------------------------------------------
local DATA_STORE_KEY: string = "New4" --데이터 스토어 키 생성
local TEST_DATA_STORE_KEY: string = "Test6" --스튜디오 전용 데이터 키 생성
local DEFAULT_PLAYER_DATA = {
	Money = 0;
	Gem = 0;
	Eat = 0;
	TutorialDone = false;
	
	Inventory = {
		
		Dish = {
			Apple = {
				Title = "Apple";
				SubTitle = "SideMenu";
				Type = "Dish";
				ActiveType = "Consumable";
				Desc = "This is Apple. Very delicious and very red!";
				Class = "E Level";
				isEquip = false;
				Amount = 1;
			};
		};
		
		Stuff = {};
		
		Accessories = {};
		
		Pet = {};
		
	};
}
---------------------------------------------------------------
----------------------/ 메인 /----------------------------------
---------------------------------------------------------------
export type DEFAULT_PLAYER_DATA = typeof(DEFAULT_PLAYER_DATA)

export type G_Types = {
	ProfileLoad: <T>(player: Player) -> T?,
	RemoveProfile: (player: Player) -> (),
	Start: () -> (),
	GetData: <T>(player: Player) -> T?,
	UpdateData: (player: Player, key: string, amount: any?) -> (),
	ClearData: (player: Player, key: string) -> (),
	ClearAllData: (player: Player) -> (),
}

if RunService:IsStudio() then
	DATA_STORE_KEY = TEST_DATA_STORE_KEY
end

local PlayerProfile = ProfileStore.New(DATA_STORE_KEY, DEFAULT_PLAYER_DATA)
local Profiles: {[player]: typeof(PlayerProfile:StartSessionAsync())} = {}

local ProfileLoad: G_Types.ProfileLoad<typeof(PlayerProfile:StartSessionAsync())> = function(player: Player)
	local profile = PlayerProfile:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		return player:Kick("프로필 로드에 실패하였습니다. 재 접속 해주세요.")
	end

	profile:AddUserId(player.UserId)
	--중복 데이터 누수 방지 :Reconcile() <-인벤토리 기능이 있는 데이터는 비활성화 권장
	--profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		Profiles[player] = nil
		player:Kick("프로필 세션이 만료되었습니다. 재 접속 해주세요.")
	end)

	local isInGame = player.Parent == Players
	if isInGame then
		Profiles[player] = profile
	else
		profile:EndSession()
	end
	
	warn("===== 플레이어 ",player.Name,"의 프로파일 로드 완료",Profiles[player])
end

local RemoveProfile: G_Types.RemoveProfile = function(player: Player)
	local profile = Profiles[player]
	if profile ~= nil then
		profile:EndSession()
	end
end
------------------------------------------------------------
------------------------/ Init /----------------------------
------------------------------------------------------------
local Start: G_Types.Start = function()
	for _, player in Players:GetChildren() do
		task.spawn(ProfileLoad, player)
	end

	Players.PlayerAdded:Connect(ProfileLoad)
	Players.PlayerRemoving:Connect(RemoveProfile)
	
	warn("===================== 현재 데이터 스토어 키 : ",DATA_STORE_KEY)
end

Start()
------------------------------------------------------------
----------------/ Global Functions /------------------------
------------------------------------------------------------
local Service = {}

function Service:GetData<T>(player: Player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		error("GetData() 인자는 반드시 Player 개체 이어야 합니다.")
	end

	local profile = Profiles[player]
	if not profile then return nil end

	return profile.Data
end


function Service:UpdateData(player: Player, key: string, amount: any?)
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


function Service:ClearData(player: Player, key: string)
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

function Service:ClearAllData(player: Player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		error("첫번째 인자(player)는 무조건 Player 개체여야 합니다.")
	end

	local data = Service:GetData(player)
	if not data then return end

	for key, defaultValue in pairs(DEFAULT_PLAYER_DATA) do
		data[key] = defaultValue
	end

	print(player.Name .. "'s data has been reset to default.")
end


return Service
