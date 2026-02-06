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
		MaxStack = 10,
		Price = 5, -- 상점 가격
		Effect = "LureCat", -- 사용 효과
	},
	CatTreat = {
		Id = "CatTreat",
		Name = "고양이 간식",
		Icon = "🐟",
		Description = "고양이를 유인하는 맛있는 간식",
		MaxStack = 5,
		Price = 20,
		Effect = "LureCat",
	},
	SpeedBoost = {
		Id = "SpeedBoost",
		Name = "에너지 드링크",
		Icon = "⚡",
		Description = "일시적으로 이동 속도 증가",
		MaxStack = 3,
		Price = 50,
		Effect = "SpeedUp",
	},
	Bungeoppang = {
		Id = "Bungeoppang",
		Name = "붕어빵",
		Icon = "🥨",
		Description = "따끈따끈한 붕어빵. 겨울철 별미",
		MaxStack = 5,
		Price = 10,
		Effect = "Heal",
	},
}

function ItemData.GetItem(itemId)
	return ItemData.Items[itemId]
end

return ItemData
