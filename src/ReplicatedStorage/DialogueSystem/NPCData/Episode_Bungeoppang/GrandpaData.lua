local DialogueData = {
	-- 1. 초기 상태: 탐색 및 퀘스트 부여
	["ST_IDLE"] = {
		Nodes = {
			["DH_IDLE_1"] = {
				Speaker = "Player",
				Text = "안녕하세요!",
				Next = "DH_IDLE_2"
			},
			["DH_IDLE_2"] = {
				Speaker = "Grandpa",
				Text = "(힐끗 쳐다보며) 무슨 일인가?",
				Choices = {
					{ Text = "혹시 근처에서 노란 고양이 못 보셨나요?", Next = "DH_IDLE_3" },
					{ Text = "아무것도 아니에요...", Next = "DH_IDLE_3_ALT1" },
					{ Text = "뭐하세요?", Next = "DH_IDLE_3_ALT2" }
				}
			},
			["DH_IDLE_3_ALT1"] = {
				Speaker = "Player",
				Text = "아무것도 아니에요...",
				Next = "DH_IDLE_3_ALT1_1"
			},
			["DH_IDLE_3_ALT1_1"] = {
				Speaker = "Grandpa",
				Text = "참 싱거운 친구구먼.",
				Next = nil -- 대화 종료
			},
			["DH_IDLE_3_ALT2"] = {
				Speaker = "Player",
				Text = "뭐하세요?",
				Next = "DH_IDLE_3_ALT2_1"
			},
			["DH_IDLE_3_ALT2_1"] = {
				Speaker = "Grandpa",
				Text = "(먼 산을 보며) 보면 모르나? 그냥 앉아서 쉬는 중이지.",
				Next = nil
			},
			["DH_IDLE_3"] = {
				Speaker = "Player",
				Text = "혹시 이 근처에서 노란 고양이 못 보셨나요?",
				Next = "DH_IDLE_4"
			},
			["DH_IDLE_4"] = {
				Speaker = "Grandpa",
				Text = "(귀찮은 듯) 노란 고양이? 이 동네에 고양이가 한둘이 아니야. 모르겠어.",
				Next = "DH_IDLE_5"
			},
			["DH_IDLE_5"] = {
				Speaker = "Player",
				Text = "몸에 핑크색 하트 모양 점이 있다고 하던데...",
				Next = "DH_IDLE_6"
			},
			["DH_IDLE_6"] = {
				Speaker = "Grandpa",
				Text = "하트 점? 글쎄... 정 찾고 싶으면 사진이라도 찍어와 봐. 아마 직접 보면 알겠지.",
				SetState = "ST_PHOTO_NEED", -- 상태 변이 트리거
				StartQuest = "FindYellowCat", -- [Added] 퀘스트 시작 트리거
				Notification = "핑크색 하트 점이 있는 노란 고양이 사진 찍어오기", 
				Next = nil
			}
		}
	},

	-- 2. 사진 촬영 대기 상태
	["ST_PHOTO_NEED"] = {
		Nodes = {
			["DH_NEED_1"] = {
				Speaker = "Grandpa",
				Text = "아직인가? 하트 점이 있는 사진을 가져와야 내가 누군지 알려주지.",
				Next = "DH_NEED_2"
			},
			["DH_NEED_2"] = {
				Speaker = "Player",
				Text = "네, 하트 점이 잘 보이게 찍어올게요!",
				Action = "OPEN_CAMERA_GUIDE", -- UI 액션 트리거 예시
				Next = nil
			}
		}
	},

	-- 3. 잘못된 사진 제출 상태
	["ST_PHOTO_WRONG"] = {
		Nodes = {
			["DH_WRONG_1"] = {
				Speaker = "Player",
				Text = "할아버지, 사진 찍어왔어요! 이 고양이 맞죠?",
				Next = "DH_WRONG_2"
			},
			["DH_WRONG_2"] = {
				Speaker = "Grandpa",
				Text = "(사진을 쓱 보더니) 에잉, 이건 그냥 동네 흔한 고양이잖아.",
				Next = "DH_WRONG_3"
			},
			["DH_WRONG_3"] = {
				Speaker = "Player",
				Text = "아... 비슷하게 생겨서 착각했나 봐요. 다시 제대로 찍어올게요!",
				SetState = "ST_PHOTO_NEED",
				Next = nil
			}
		}
	},

	-- 4. 사진 확인 및 사연 인지 성공 상태
	["ST_PHOTO_SUCCESS"] = {
		Nodes = {
			["DH_SUCCESS_1"] = {
				Speaker = "Player",
				Text = "할아버지, 여기요! 겨우 찍었어요. 이 사진 속 고양이 보세요. 핑크색 하트 점이 선명하죠?",
				Next = "DH_SUCCESS_2"
			},
			["DH_SUCCESS_2"] = {
				Speaker = "Grandpa",
				Text = "허어, 이 녀석이었구먼. 그래, 이 핑크색 하트 점... '노랑이'구나. 앞집 꼬마가 지어준 이름이지. 이 녀석을 구조하겠다고?",
				Next = "DH_SUCCESS_3"
			},
			["DH_SUCCESS_3"] = {
				Speaker = "Player",
				Text = "노랑이요? 이 고양이를 잘 아시나 봐요?",
				Next = "DH_SUCCESS_4"
			},
			["DH_SUCCESS_4"] = {
				Speaker = "Grandpa",
				Text = "앞집 꼬마가 아주 아끼던 놈이었어. 매일 같이 붙어 다녔지.",
				Next = "DH_SUCCESS_5"
			},
			["DH_SUCCESS_5"] = {
				Speaker = "Player",
				Text = "그런데 왜 안 데려갔어요? 고양이가 너무 가여워요.",
				Next = "DH_SUCCESS_6"
			},
			["DH_SUCCESS_6"] = {
				Speaker = "Grandpa",
				Text = "이삿날 아침에 어디 숨었는지, 꼬마애가 울면서 찾아도 끝내 못찾았나 보더라고.",
				Next = "DH_SUCCESS_7"
			},
			["DH_SUCCESS_7"] = {
				Speaker = "Player",
				Text = "결국 꼬마가 떠날 때까지 못 보고 엇갈려 버린 거네요...",
				Next = "DH_SUCCESS_8"
			},
			["DH_SUCCESS_8"] = {
				Speaker = "Grandpa",
				Text = "트럭이 떠나고 나서야 알고 쫓아갔지만, 결국 놓쳤지. 그날부터 매일 여기서 기다리기만 하다가 저렇게 기운이 다 빠진 게야.",
				Next = "DH_SUCCESS_9"
			},
			["DH_SUCCESS_9"] = {
				Speaker = "Grandpa",
				Text = "자, 이건 내가 아끼던 덫일세. 그리고 이 붕어빵도 가져가게나. 노랑이가 이걸 보면 마음을 좀 열지도 모르니...",
				Action = "GiveItem",
				ItemID = "CatTrap",
				SetState = "ST_ITEM_NONE", -- 상태 전이
				Next = "DH_SUCCESS_10"
			},
			["DH_SUCCESS_10"] = {
				Speaker = "Grandpa",
				Text = "(붕어빵 하나를 더 건네며) 붕어빵 하나면 부족할지 모르니 하나는 자네가 먹어도 좋고. 꼭 구조해주게나.",
				Action = "GiveItem",
				ItemID = "Bungeoppang",
				NotificationTitle = "아이템 획득", -- [Added] 제목 분리
				Notification = "붕어빵, 고양이 덫", 
				Next = nil
			}
		}
	},

	-- 5. 아이템 없음 상태
	["ST_ITEM_NONE"] = {
		Nodes = {
			["DH_NONE_1"] = {
				Speaker = "Player",
				Text = "노랑이 녀석... 구조하고 싶은데, 잡을 수가 없네요. 어쩌죠?",
				Next = "DH_NONE_2"
			},
			["DH_NONE_2"] = {
				Speaker = "Grandpa",
				Text = "녀석 참 고집 세지? 음... 옛날엔 붕어빵 냄새만 맡아도 자다가 달려오곤 했어. 그 꼬마랑 같이 나눠 먹던 그 향기를 아직도 못 잊는 게지. 불쌍한 녀석...",
				Next = "DH_NONE_3"
			},
			["DH_NONE_3"] = {
				Speaker = "Player",
				Text = "아... 붕어빵 냄새요? 그럼 그 냄새로 노랑이를 유인해볼 수 있을까요?",
				Next = "DH_NONE_4"
			},
			["DH_NONE_4"] = {
				Speaker = "Grandpa",
				Text = "붕어빵은 저기 포장마차에서 팔고 있으니 필요하면 여기서 사 가면 될 걸세.",
				Next = "DH_NONE_5"
			},
			["DH_NONE_5"] = {
				Speaker = "Player",
				Text = "잘됐네요! 알려주셔서 고맙습니다!",
				NotificationTitle = "새로운 목표", -- [Added] 제목 분리
				Notification = "포장마차에서 붕어빵 구하기", 
				Next = nil
			}
		}
	},

	-- 6. 붕어빵만 있는 상태
	["ST_ITEM_ONLY_BAIT"] = {
		Nodes = {
			["DH_OBAIT_1"] = {
				Speaker = "Player",
				Text = "할아버지, 붕어빵은 샀는데 이제 그냥 가서 잡으면 될까요?",
				Next = "DH_OBAIT_2"
			},
			["DH_OBAIT_2"] = {
				Speaker = "Grandpa",
				Text = "붕어빵만 있다고 되는 게 아니야. 녀석 경계심이 보통이 아니라 맨손으론 어림없거든.",
				Next = "DH_OBAIT_3"
			},
			["DH_OBAIT_3"] = {
				Speaker = "Player",
				Text = "아... 그럼 어떡하죠? 그냥 지켜만 볼 수도 없고요.",
				Next = "DH_OBAIT_4"
			},
			["DH_OBAIT_4"] = {
				Speaker = "Grandpa",
				Text = "마을 상점에 가보게. 거기서 고양이를 안전하게 구조할 수 있는 덫을 팔 거야.",
				Next = "DH_OBAIT_5"
			},
			["DH_OBAIT_5"] = {
				Speaker = "Player",
				Text = "그렇군요. 붕어빵과 덫이 필요하군요! 고맙습니다. 할아버지!",
				Next = "DH_OBAIT_6"
			},
			["DH_OBAIT_6"] = {
				Speaker = "Grandpa",
				Text = "허허, 그래 조심히 다녀오게나.",
				NotificationTitle = "새로운 목표", -- [Added] 제목 분리
				Notification = "상점에서 고양이 덫 구하기", 
				Next = nil
			}
		}
	},

	-- 7. 덫만 있는 상태
	["ST_ITEM_ONLY_TRAP"] = {
		Nodes = {
			["DH_OTRAP_1"] = {
				Speaker = "Player",
				Text = "할아버지, 상점에서 덫은 구해왔어요! 이제 구조할 수 있겠죠?",
				Next = "DH_OTRAP_2"
			},
			["DH_OTRAP_2"] = {
				Speaker = "Grandpa",
				Text = "덫만으론 안 되지. 노랑이는 붕어빵을 좋아한다구! 냄새나는 미끼가 있어야 녀석이 올 거 아냐.",
				Next = "DH_OTRAP_3"
			},
			["DH_OTRAP_3"] = {
				Speaker = "Player",
				Text = "아, 맞다! 포장마차에서 붕어빵을 사야겠네요!",
				NotificationTitle = "새로운 목표", -- [Added] 제목 분리
				Notification = "붕어빵 구하기", 
				Next = nil
			}
		}
	},

	-- 8. 모든 준비 완료 상태
	["ST_ITEM_READY"] = {
		Nodes = {
			["DH_READY_1"] = {
				Speaker = "Player",
				Text = "할아버지, 붕어빵이랑 덫 둘 다 챙겼어요! 이제 정말 가볼게요!",
				Next = "DH_READY_2"
			},
			["DH_READY_2"] = {
				Speaker = "Grandpa",
				Text = "다 있는데 안 잡고 여기서 뭐 하고 있어? 붕어빵 식기 전에 어서 가봐!",
				Next = "DH_READY_3"
			},
			["DH_READY_3"] = {
				Speaker = "Player",
				Text = "네! 꼭 구조해서 올게요!",
				NotificationTitle = "최종 목표", -- [Added] 제목 분리
				Notification = "고양이 포획하기", 
				Next = nil
			}
		}
	},

	-- 9. 고양이 구조 성공 후 최종 대화
	["ST_CATCH_SUCCESS"] = {
		Nodes = {
			["DH_FINAL_1"] = {
				Speaker = "Grandpa",
				Text = "오! 정말 노랑이를 구조했구먼! 고생 많았네.",
				Next = "DH_FINAL_2"
			},
			["DH_FINAL_2"] = {
				Speaker = "Player",
				Text = "할아버지 덕분이에요. 이제 안전한 곳으로 데려갈게요.",
				Next = "DH_FINAL_3"
			},
			["DH_FINAL_3"] = {
				Speaker = "Grandpa",
				Text = "그래, 그 꼬마도 이 소식을 들으면 정말 기뻐할 게야. 자네가 참 큰일을 했어.",
				Next = nil
			}
		}
	}
}

-- [추가된 레이어] 상태 결정 로직
function DialogueData.GetActualState(player, savedState)
	-- InventoryManager 참조 (서버 사이드 전제)
	local invManager = _G.InventoryManager

	-- 아이템 관련 상태 그룹인 경우에만 인벤토리 체크 실행
	-- 또는 사진 퀘스트 완료 직후(ST_ITEM_NONE)여도 체크해야 자연스럽게 넘어감
	if savedState == "ST_ITEM_NONE" or string.find(savedState, "ST_ITEM_") then
		local hasBait = false
		local hasTrap = false
		
		if invManager then
			hasBait = invManager.HasItem(player, "Bungeoppang")
			hasTrap = invManager.HasItem(player, "CatTrap")
		end

		if hasBait and hasTrap then
			return "ST_ITEM_READY"
		elseif hasBait then
			return "ST_ITEM_ONLY_BAIT"
		elseif hasTrap then
			return "ST_ITEM_ONLY_TRAP"
		else
			return "ST_ITEM_NONE"
		end
	end

	-- 아이템 체크 단계가 아니면 저장된 상태 그대로 반환
	return savedState
end

return DialogueData


