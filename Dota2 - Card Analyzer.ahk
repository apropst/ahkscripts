#NoEnv
SetBatchLines -1
ListLines Off
SendMode Input
SetWorkingDir %A_ScriptDir%

; TODO
; 1) Create scoring algorithm
; 2) Add processing of multiple cards per player
; 3) Add processing of entire team list - maybe require manual changing between players?
; 4) Add persistent storage of card info

global cardLocation := {}
global cardType :=
global playerRole :=
global modType := []
global percent := []
global cardTypeList := ["Silver", "Gold", "Green"]
global roleList := ["Core", "Offlane", "Support"]
global modTypeList := ["CampsStacked", "CreepScore", "Deaths", "FirstBlood", "GPM", "Kills", "ObsWardsPlanted", "RoshanKills", "RunesGrabbed", "Stuns", "Teamfight", "TowerKills"]
global coreScoreList := [0, 1.2, 2.3, 0.9, 1.3, 2.9, 0, 0.9, 4.4, 3.5, 2.3, 3.4]
global offlaneScoreList := [0, 0, 0, 0.9, 0, 0, 0, 0, 4.4, 3.5, 2.3, 0]
global supportScoreList := [1.8, 0, 0, 0.9, 0, 0, 7, 0, 4.4, 3.5, 2.3, 0]
global percentList := ["5", "10", "15", "20", "25"]
global cardScore := 0

IfWinExist Dota 2
{
	WinActivate
	
	cardType := GetCardType()
	
	playerRole := GetRole()
	
	GetMods()
	
	messageString := GenerateDebug()
	
	MsgBox %messageString%
}
ExitApp

GetCardType()
{
	For index, currentCardType in cardTypeList
	{
		ImageSearch, topLeftX, topLeftY, 0, 0, A_ScreenWidth, A_ScreenHeight, %A_ScriptDir%\Images\Dota2-CardAnalyzer\Corners\CardTopLeft%currentCardType%.png
		
		If ErrorLevel = 0
		{
			ImageSearch, bottomRightX, bottomRightY, topLeftX, topLeftY, A_ScreenWidth, A_ScreenHeight, %A_ScriptDir%\Images\Dota2-CardAnalyzer\Corners\CardBottomRight%currentCardType%.png
			
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
	For index, playerRole in roleList
	{
		ImageSearch, foundX, foundY, cardLocation.topLeftX, cardLocation.topLeftY, cardLocation.bottomRightX, cardLocation.bottomRightY, %A_ScriptDir%\Images\Dota2-CardAnalyzer\Roles\%playerRole%%cardType%.png
		
		If ErrorLevel = 0
			return %playerRole%
	}
}

GetMods()
{
	For index, currentModType in modTypeList
	{		
		ImageSearch, foundX, foundY, cardLocation.topLeftX, cardLocation.topLeftY, cardLocation.bottomRightX, cardLocation.bottomRightY, *30 %A_ScriptDir%\Images\Dota2-CardAnalyzer\Mods\%currentModType%%cardType%.png
		
		If ErrorLevel = 0
		{
			modType.Push(currentModType)
			modPercent := GetPercent(foundX, foundY)
			percent.Push(modPercent)
			
			StringLower, roleLower, playerRole
			cardScore := cardScore + (%roleLower%ScoreList[index] * (modPercent / 100))
		}
	}
}

GetPercent(topX, topY)
{
	For indexPer, elementPer in percentList
	{
		currentPercent := percentList[indexPer]
		
		ImageSearch, foundX, foundY, topX, topY, topX + 400, topY + 25, *40 %A_ScriptDir%\Images\Dota2-CardAnalyzer\Percents\%currentPercent%%cardType%.png
		
		If ErrorLevel = 0
			return %currentPercent%
	}
}

GenerateDebug()
{
	messageString := "Card Type: " cardType "`n`n"
	
	messageString .= "Role: " playerRole "`n"
	
	If modType.Length() > 0
		messageString .= "`nFound the following mods:`n"
	
	for index, element in modType
	{
		messageString .= modType[index] ": " percent[index] "%`n"
	}
	
	If modType.Length() > 0
	{
		messageString .= "`n"
		messageString .= "Card Score: " TrimNumberStr(cardScore)
	}
	
	return messageString
}

TrimNumberStr(num)
{
	Loop, % StrLen(num)
	{
		stringright, tester, num, 1
		If (tester = "0")
			stringtrimright, num, num, 1
	}
	
	return num
}