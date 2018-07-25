#NoEnv
SetBatchLines -1
ListLines Off
SendMode Input
SetWorkingDir %A_ScriptDir%

; TODO
; 1) Add processing of multiple cards per player
; 2) Add logical cut-off for image searches, stop after 3 mods are found for silver and 5 for gold
; 3) Add processing of entire team list - maybe require manual changing between players?
; 4) Add persistent storage of card info
; 5) Integrate TI8 fantasy algorithm
; 6) Integrate TI7 player data
; 7) Provide Fantasy pick recommendations, with ability to remove teams that aren't in TI anymore

global coreScoreList := [0, 1.2, 2.3, 0.9, 1.3, 2.9, 0, 0.9, 4.4, 3.5, 2.3, 3.4]
global offlaneScoreList := [0, 0, 0, 0.9, 0, 0, 0, 0, 4.4, 3.5, 2.3, 0]
global supportScoreList := [1.8, 0, 0, 0.9, 0, 0, 7, 0, 4.4, 3.5, 2.3, 0]
global percentList := ["5", "10", "15", "20", "25"]
global cardScore := 0

IfWinExist Dota 2
{
	WinActivate
	
	cardTypeList := ["Silver", "Gold", "Green"]
	roleList := ["Core", "Offlane", "Support"]
	modTypeList := ["CampsStacked", "CreepScore", "Deaths", "FirstBlood", "GPM", "Kills", "ObsWardsPlanted", "RoshanKills", "RunesGrabbed", "Stuns", "Teamfight", "TowerKills"]
	modType := []
	percent := []
	
	cardLocation := GetCardLocation(cardTypeList)
	
	cardType := GetCardType(cardTypeList, cardLocation)
	
	playerRole := GetRole(roleList, cardLocation, cardType)
	
	GetMods(modType, percent, modTypeList, cardLocation, cardType, playerRole)
	
	messageString := GenerateDebug(cardType, playerRole, modType, percent)
	
	MsgBox %messageString%
}
ExitApp

ImageSearch(ByRef x, ByRef y, x1, y1, x2, y2, file)
{
	ImageSearch, x, y, % x1, % y1, % x2, % y2, % file
	
	return !ErrorLevel
}

GetCardLocation(cardTypeList)
{
	cardLocation := {}
	
	For index, currentCardType in cardTypeList
	{
		If ImageSearch(cardLocation.topLeftX, cardLocation.topLeftY, 0, 0, A_ScreenWidth, A_ScreenHeight, A_ScriptDir "\Images\Dota2-CardAnalyzer\Corners\CardTopLeft" currentCardType ".png")
		{
			ImageSearch(bottomRightX, bottomRightY, cardLocation.topLeftX, cardLocation.topLeftY, A_ScreenWidth, A_ScreenHeight, A_ScriptDir "\Images\Dota2-CardAnalyzer\Corners\CardBottomRight" currentCardType ".png")
			
			cardLocation.bottomRightX := bottomRightX
			cardLocation.bottomRightY := bottomRightY
			
			return cardLocation
		}
	}
}

GetCardType(cardTypeList, cardLocation)
{
	For index, currentCardType in cardTypeList
	{
		If ImageSearch(topLeftX, topLeftY, cardLocation.topLeftX, cardLocation.topLeftY, cardLocation.bottomRightX, cardLocation.bottomRightY, A_ScriptDir "\Images\Dota2-CardAnalyzer\Corners\CardTopLeft" currentCardType ".png")
			return %currentCardType%
	}
}

GetRole(roleList, cardLocation, cardType)
{
	For index, playerRole in roleList
	{
		If ImageSearch(foundX, foundY, cardLocation.topLeftX, cardLocation.topLeftY, cardLocation.bottomRightX, cardLocation.bottomRightY, "*1 " A_ScriptDir "\Images\Dota2-CardAnalyzer\Roles\" playerRole cardType ".png")
			return %playerRole%
	}
}

GetMods(ByRef modType, ByRef percent, modTypeList, cardLocation, cardType, playerRole)
{
	For index, currentModType in modTypeList
	{		
		If ImageSearch(foundX, foundY, cardLocation.topLeftX, cardLocation.topLeftY, cardLocation.bottomRightX, cardLocation.bottomRightY, "*30 " A_ScriptDir "\Images\Dota2-CardAnalyzer\Mods\" currentModType cardType ".png")
		{
			modType.Push(currentModType)
			modPercent := GetPercent(foundX, foundY, cardType)
			percent.Push(modPercent)
			
			StringLower, roleLower, playerRole
			cardScore := cardScore + (%roleLower%ScoreList[index] * (modPercent / 100))
		}
	}
}

GetPercent(topX, topY, cardType)
{
	For indexPer, elementPer in percentList
	{
		currentPercent := percentList[indexPer]
		
		If ImageSearch(foundX, foundY, topX + 300, topY, topX + 400, topY + 25, "*40 " A_ScriptDir "\Images\Dota2-CardAnalyzer\Percents\" currentPercent cardType ".png")
			return %currentPercent%
	}
}

GenerateDebug(cardType, playerRole, modType, percent)
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