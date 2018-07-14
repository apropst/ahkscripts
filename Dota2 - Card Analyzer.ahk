#NoEnv
SetBatchLines -1
ListLines Off
SendMode Input
SetWorkingDir %A_ScriptDir%

; TODO
; 1) Add images and processing for gold cards
; 2) Create scoring algorithm
; 3) Add processing of multiple cards per player
; 4) Add processing of entire team list - maybe require manual changing between players?
; 5) Add persistent storage of card info

global cardLocation := {}
global cardType :=
global modType := []
global percent := []
global cardTypeList := ["Silver", "Gold", "Green"]
global roleList := ["Core", "Offlane", "Support"]
global modTypeList := ["CampsStacked", "CreepScore", "Deaths", "FirstBlood", "Kills", "ObsWardsPlanted", "RoshanKills", "RunesGrabbed", "Stuns", "Teamfight", "TowerKills"]
global percentList := ["5", "10", "15", "20", "25"]

IfWinExist Dota 2
{
	WinActivate
	
	cardType := GetCardType()
	
	role := GetRole()
	
	GetModType()
	
	messageString .= "Card Type: " cardType "`n"
	
	If modType.Length() > 0
		messageString .= "`nFound the following mods:`n"
	
	for index, element in modType
	{
		messageString .= modType[index] ": " percent[index] "%`n"
	}
	
	If modType.Length() > 0
		messageString .= "`n"
	
	messageString .= "Role: " role "`n`n"
	
	messageString .= "Top Right: " cardLocation.topLeftX "x" cardLocation.topLeftY "`n"
	
	messageString .= "Bottom Right: " cardLocation.bottomRightX "x" cardLocation.bottomRightY "`n"
	
	MsgBox %messageString%
}
ExitApp

GetCardType()
{
	For index, currentCardType in cardTypeList
	{
		ImageSearch, topLeftX, topLeftY, 0, 0, A_ScreenWidth, A_ScreenHeight, %A_ScriptDir%\Images\Dota2-CardAnalyzer\CardTopLeft%currentCardType%.png
		
		If ErrorLevel = 0
		{
			ImageSearch, bottomRightX, bottomRightY, topLeftX, topLeftY, A_ScreenWidth, A_ScreenHeight, %A_ScriptDir%\Images\Dota2-CardAnalyzer\CardBottomRight%currentCardType%.png
			
			cardLocation.topLeftX := topLeftX
			cardLocation.topLeftY := topLeftY
			cardLocation.bottomRightX := bottomRightX
			cardLocation.bottomRightY := bottomRightY
			
			return %currentCardType%
		}
	}
}

GetRole()
{
	For index, role in roleList
	{
		ImageSearch, foundX, foundY, cardLocation.topLeftX, cardLocation.topLeftY, cardLocation.bottomRightX, cardLocation.bottomRightY, %A_ScriptDir%\Images\Dota2-CardAnalyzer\%role%.png
		
		If ErrorLevel = 0
			return %role%
	}
}

GetModType()
{
	For index, currentModType in modTypeList
	{		
		ImageSearch, foundX, foundY, cardLocation.topLeftX, cardLocation.topLeftY, cardLocation.bottomRightX, cardLocation.bottomRightY, *15 %A_ScriptDir%\Images\Dota2-CardAnalyzer\%currentModType%.png
		
		If ErrorLevel = 0
		{
			modType.Push(currentModType)
			percent.Push(GetPercent(foundX, foundY))
		}
	}
}

GetPercent(topX, topY)
{
	For indexPer, elementPer in percentList
	{
		currentPercent := percentList[indexPer]
		
		ImageSearch, foundX, foundY, topX, topY, topX + 400, topY + 25, *15 %A_ScriptDir%\Images\Dota2-CardAnalyzer\%currentPercent%.png
		
		If ErrorLevel = 0
			return %currentPercent%
	}
}