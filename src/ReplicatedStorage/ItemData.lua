-- ItemData.lua
-- 아이템 정의 모듈
-- ReplicatedStorage에 위치

local ItemData = {}

ItemData.Items = {
	Stick = {
		Id = "Stick",
		Name = "나뭇가지",
		Icon = "🌿",
		Description = "평범한 나뭇가지. 고양이가 좋아할지도?",
		MaxStack = 999,
		Price = 5, -- 상점 가격
		Effect = "LureCat", -- 사용 효과
	},
	SpeedBoost = {
		Id = "SpeedBoost",
		Name = "에너지 드링크",
		Icon = "⚡",
		Description = "일시적으로 이동 속도 증가",
		MaxStack = 999,
		Price = 50,
		Effect = "SpeedUp",
	},
	Bungeoppang = {
		Id = "Bungeoppang",
		Name = "붕어빵",
		Icon = "🥨",
		Description = "따끈따끈한 붕어빵. 겨울철 별미",
		MaxStack = 999,
		Price = 10,
		Effect = "Heal",
	},
	CatTrap = {
		Id = "CatTrap",
		Name = "고양이 덫",
		Icon = "📦", -- 박스 아이콘
		Description = "고양이를 잡을 수 있는 덫. 사용하면 설치된다.",
		MaxStack = 999,
		Price = 100,
		Effect = "SummonTrap",
	},
	CatChuru = {
		Id = "CatChuru",
		Name = "고양이 츄르",
		Icon = "🍭",
		Description = "마약 같은 고양이 간식. 모든 고양이를 유혹할 수 있다.",
		MaxStack = 999,
		Price = 20,
		Effect = "LureCatHigh",
	},
	CatCan = {
		Id = "CatCan",
		Name = "고양이 통조림",
		Icon = "🥫",
		Description = "배고픈 고양이를 위한 든든한 통조림.",
		MaxStack = 999,
		Price = 30,
		Effect = "LureCatMedium",
	},
}

function ItemData.GetItem(itemId)
	return ItemData.Items[itemId]
end

return ItemData
