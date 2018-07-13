#NoEnv
SetBatchLines -1
ListLines Off
SendMode Input
SetWorkingDir %A_ScriptDir%

; TODO
; 1) Add getting of card type
; 2) Add images and processing for gold cards
; 3) Create scoring algorithm

global cardLocation := {}
global ModType := []
global Percent := []
global RoleList := ["Core", "Offlane", "Support"]
global ModTypeList := ["CampsStacked", "CreepScore", "Deaths", "FirstBlood", "Kills", "ObsWardsPlanted", "RoshanKills", "RunesGrabbed", "Stuns", "Teamfight", "TowerKills"]
global PercentList := ["5", "10", "15", "20", "25"]

IfWinExist Dota 2
{
	WinActivate
	
	GetCardLocation()
	
	role := GetRole()
	
	For index, element in ModTypeList
	{		
		CurrentMod := ModTypeList[index]
		
		ImageSearch, FoundX, FoundY, cardLocation.TopLeftX, cardLocation.TopLeftY, cardLocation.BottomRightX, cardLocation.BottomRightY, *15 %A_ScriptDir%\Images\Dota2-CardAnalyzer\%CurrentMod%.png
		
		If ErrorLevel = 0
		{
			ModType.Push(CurrentMod)
			Percent.Push(GetPercent(FoundX, FoundY))
		}
	}
	
	MessageString := "Found the following mods:"
	
	for index, element in ModType
	{
		MessageString .= "`n" ModType[index] ": " Percent[index] "%"
	}
	
	MessageString .= "`nRole: " role
	
	MessageString .= "`nTop Right: " cardLocation.TopLeftX "x" cardLocation.TopLeftY
	
	MessageString .= "`nBottom Right: " cardLocation.BottomRightX "x" cardLocation.BottomRightY
	
	MsgBox %MessageString%
}
ExitApp

GetCardLocation()
{
	ImageSearch, TopLeftX, TopLeftY, 0, 0, A_ScreenWidth, A_ScreenHeight, %A_ScriptDir%\Images\Dota2-CardAnalyzer\CardTopLeft.png
	ImageSearch, BottomRightX, BottomRightY, 0, 0, A_ScreenWidth, A_ScreenHeight, %A_ScriptDir%\Images\Dota2-CardAnalyzer\CardBottomRight.png
	cardLocation.TopLeftX := TopLeftX
	cardLocation.TopLeftY := TopLeftY
	cardLocation.BottomRightX := BottomRightX
	cardLocation.BottomRightY := BottomRightY
	return
}

GetRole()
{
	For index, element in RoleList
	{
		CurrentRole := RoleList[index]
		
		ImageSearch, FoundX, FoundY, cardLocation.TopLeftX, cardLocation.TopLeftY, cardLocation.BottomRightX, cardLocation.BottomRightY, %A_ScriptDir%\Images\Dota2-CardAnalyzer\%CurrentRole%.png
		
		If ErrorLevel = 0
			return %CurrentRole%
	}
}

GetModType()
{

}

GetPercent(TopX, TopY)
{
	For indexPer, elementPer in PercentList
	{
		CurrentPercent := PercentList[indexPer]
		
		ImageSearch, FoundX, FoundY, TopX, TopY, TopX + 400, TopY + 25, *15 %A_ScriptDir%\Images\Dota2-CardAnalyzer\%CurrentPercent%.png
		
		If ErrorLevel = 0
			return %CurrentPercent%
	}
}