local SellerData = {
    DefaultState = "ST_IDLE",
    
    -- DialogueManager의 GetActualState 호환 여부 (필요 시 로직 확장 가능)
    GetActualState = function(player, savedState)
        return savedState
    end,

    Dialogue = {
        ["ST_IDLE"] = {
            Nodes = {
                ["D_1"] = {
                    Text = "어서오세요!\n찾으시는 물건이 있나요?",
                    Speaker = "Seller", -- 점원
                    Choices = {
                        {
                            Text = "물건 구매하기",
                            Action = "OPEN_SHOP_UI",  -- [중요] DialogueUI.client.lua에서 인터셉트할 Action String
                        },
                        {
                            Text = "그냥 둘러볼게요.",
                            Next = "D_EXIT" 
                        }
                    }
                },
                ["D_EXIT"] = {
                    Text = "네, 편하게 둘러보시고 필요한 게 있으면 말씀해 주세요!",
                    Speaker = "Seller",
                    -- Next가 없으면 대화 자동 종료
                }
            }
        }
    }
}

return SellerData
