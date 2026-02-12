local DialogueData = {
	-- 1. 초기 상태: 인사 및 상점 유도
	["ST_IDLE"] = {
		Nodes = {
			["DH_CHEF_1"] = {
				Speaker = "Chef",
				Text = "어서 오세요, {PlayerName}님! 갓 구운 붕어빵 있습니다. 무엇을 도와드릴까요?",
				Choices = {
					{ Text = "붕어빵을 사고 싶어요.", Next = "DH_CHEF_SHOP_BAIT" },
					{ Text = "길고양이 구조용 덫이 있나요?", Next = "DH_CHEF_SHOP_TRAP" },
					{ Text = "다른 물건은 없나요?", Next = "DH_CHEF_SHOP_LIST" },
					{ Text = "그냥 구경 중이에요.", Next = "DH_CHEF_EXIT" }
				}
			},
			["DH_CHEF_EXIT"] = {
				Speaker = "Chef",
				Text = "네, 천천히 구경하세요!",
				Next = nil
			},
			-- 붕어빵 구매
			["DH_CHEF_SHOP_BAIT"] = {
				Speaker = "Chef",
				Text = "붕어빵 말이죠? 여기 있습니다! 뜨거우니 조심하세요.",
				Action = "GiveItem",
				ItemID = "Bungeoppang",
				Amount = 1,
				Next = "DH_CHEF_SHOP_CONTINUE"
			},
			-- 덫 구매
			["DH_CHEF_SHOP_TRAP"] = {
				Speaker = "Chef",
				Text = "구조용 덫이요? 마침 재고가 하나 남았네요. 여기 있습니다.",
				Action = "GiveItem",
				ItemID = "CatTrap",
				Amount = 1,
				Next = "DH_CHEF_SHOP_CONTINUE"
			},
			-- 상점 리스트 (기타)
			["DH_CHEF_SHOP_LIST"] = {
				Speaker = "Chef",
				Text = "고양이 간식이나 통조림도 구비되어 있습니다. 무엇이 필요하신가요?",
				Choices = {
					{ Text = "고양이 츄르 (20코인)", Next = "DH_CHEF_SHOP_CHURU" },
					{ Text = "고양이 통조림 (30코인)", Next = "DH_CHEF_SHOP_CAN" },
					{ Text = "돌아가기", Next = "DH_CHEF_1" }
				}
			},
			["DH_CHEF_SHOP_CHURU"] = {
				Speaker = "Chef",
				Text = "츄르 여기 있습니다! 고양이들이 환장할 거예요.",
				Action = "GiveItem",
				ItemID = "CatChuru",
				Amount = 1,
				Next = "DH_CHEF_SHOP_CONTINUE"
			},
			["DH_CHEF_SHOP_CAN"] = {
				Speaker = "Chef",
				Text = "통조림 여기 있습니다. 배고픈 고양이에게 최고죠.",
				Action = "GiveItem",
				ItemID = "CatCan",
				Amount = 1,
				Next = "DH_CHEF_SHOP_CONTINUE"
			},
			-- 계속 쇼핑할지 묻기
			["DH_CHEF_SHOP_CONTINUE"] = {
				Speaker = "Chef",
				Text = "다른 것도 더 필요하신가요?",
				Choices = {
					{ Text = "네, 더 볼게요.", Next = "DH_CHEF_1" },
					{ Text = "아니요, 충분해요.", Next = "DH_CHEF_EXIT" }
				}
			}
		}
	}
}

-- 상태 결정 로직 (특별한 조건 없으면 그대로 반환)
function DialogueData.GetActualState(player, savedState)
	return savedState or "ST_IDLE"
end

return DialogueData
