local EpisodeData = {
	["FindYellowCat"] = {
		Title = "노란 고양이 찾기",
		Description = "할아버지가 잃어버린 노란 고양이를 찾아주세요. 핑크색 하트 점이 있다고 합니다.",
		Objectives = {
			{ Type = "TakePhoto", Target = "YellowCat", Count = 1, Description = "핑크색 하트 점이 있는 노란 고양이 사진 찍기" }
		},
		Rewards = {
			Money = 500,
			Exp = 100
		},
		NextQuest = "RescueYellowCat"
	},
	["RescueYellowCat"] = {
		Title = "노란 고양이 구조",
		Description = "노란 고양이를 구조하기 위해 필요한 도구를 모으고 덫을 설치하세요.",
		Objectives = {
			{ Type = "GetItem", Target = "Bungeoppang", Count = 1, Description = "붕어빵 구하기" },
			{ Type = "GetItem", Target = "CatTrap", Count = 1, Description = "고양이 덫 구하기" },
			{ Type = "CatchCat", Target = "YellowCat", Count = 1, Description = "고양이 구조하기" }
		},
		Rewards = {
			Money = 1000,
			Exp = 200,
			Item = "SpecialCatTreat"
		},
		NextQuest = nil
	}
}

return EpisodeData
