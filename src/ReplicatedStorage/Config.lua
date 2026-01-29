-- Config.lua
-- 게임 전역 설정 파일
-- 이 모듈은 ReplicatedStorage에 위치하여 서버와 클라이언트 모두 접근할 수 있어야 합니다.

local Config = {}

-- 팀 설정
Config.Teams = {
	Red = {
		Name = "Red Team",
		Color = Color3.fromRGB(255, 100, 100)
	},
	Blue = {
		Name = "Blue Team",
		Color = Color3.fromRGB(100, 100, 255)
	}
}

-- 맵 생성 설정
Config.Map = {
	Size = 200, -- 맵 크기 (200x200)
	PlotSize = 4, -- 그리드 단위
	RoadWidth = 16, -- 도로 너비
	BuildingCount = 10, -- 시도할 건물 수
	CarCount = 5, -- 배치할 차 수
	BikeCount = 5, -- 배치할 오토바이 수
}

-- 카메라 설정
Config.Camera = {
	Name = "Camera",
	ShutterSpeed = 0.5, -- 촬영 간격 (초)
	Range = 100, -- 초점 거리
}

-- 게임 라운드 설정
Config.Game = {
	RoundDuration = 300, -- 라운드 시간 (초) = 5분
	IntermissionDuration = 3, -- 대기 시간 단축 (빠른 시작)
	RespawnTime = 3, -- 리스폰 시간
}

return Config
