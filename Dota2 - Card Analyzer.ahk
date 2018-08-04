#NoEnv
SetBatchLines -1
ListLines Off
SendMode Input
SetWorkingDir %A_ScriptDir%

; TODO
; 1) Add processing of entire team list - maybe require manual changing between players?
; 2) Add persistent storage of card info
; 3) Integrate TI8 fantasy algorithm
; 4) Integrate TI7 player data
; 5) Provide Fantasy pick recommendations, with ability to remove teams that aren't in TI anymore

IfWinExist Dota 2
{
	WinActivate
	
	cardTypeList := ["Silver", "Gold", "Green"]
	cardList := {}
	
	cardLocation := GetCardLocation(cardTypeList)
	
	Loop {
		modList := []
		percent := []
		
		card := {}
		card.cardType := GetCardType(cardTypeList, cardLocation)
		card.playerRole := GetRole(cardLocation, card%cardNum%.cardType)
		If card.cardType != "Green"
			card.cardScore := GetMods(modList, percent, cardLocation, card%cardNum%.cardType, card%cardNum%.playerRole)
		card.modList := modList
		card.percent := percent
		cardList.Push(card)
		
		If ImageSearch(nextButtonX, nextButtonY, cardLocation.topLeftX, cardLocation.bottomRightY, cardLocation.bottomRightX, cardLocation.bottomRightY + 200, "*5 " A_ScriptDir "\Images\Dota2-CardAnalyzer\Buttons\NextButtonActive.png") {
			MouseClick, left, % nextButtonX + 5, % nextButtonY + 5
			
			MouseMove, 100, 100
			
			Sleep, 250
		} else {
			break
		}
	}
	
	messageString := GenerateDebug(cardList)
	
	MsgBox %messageString%
}
ExitApp

ImageSearch(ByRef x, ByRef y, x1, y1, x2, y2, file) {
	ImageSearch, x, y, % x1, % y1, % x2, % y2, % file
	
	return !ErrorLevel
}

GetCardLocation(cardTypeList) {
	cardLocation := {}
	
	For index, currentCardType in cardTypeList {
		If ImageSearch(cardLocation.topLeftX, cardLocation.topLeftY, 0, 0, A_ScreenWidth, A_ScreenHeight, A_ScriptDir "\Images\Dota2-CardAnalyzer\Corners\CardTopLeft" currentCardType ".png") {
			ImageSearch(bottomRightX, bottomRightY, cardLocation.topLeftX, cardLocation.topLeftY, A_ScreenWidth, A_ScreenHeight, A_ScriptDir "\Images\Dota2-CardAnalyzer\Corners\CardBottomRight" currentCardType ".png")
				
			cardLocation.bottomRightX := bottomRightX
			cardLocation.bottomRightY := bottomRightY
			
			return cardLocation
		}
	}
}

GetCardType(cardTypeList, cardLocation) {
	For index, currentCardType in cardTypeList {
		If ImageSearch(topLeftX, topLeftY, cardLocation.topLeftX, cardLocation.topLeftY, cardLocation.bottomRightX, cardLocation.bottomRightY, A_ScriptDir "\Images\Dota2-CardAnalyzer\Corners\CardTopLeft" currentCardType ".png")
			return %currentCardType%
	}
}

GetRole(cardLocation, cardType) {
	roleList := ["Core", "Offlane", "Support"]

	For index, playerRole in roleList {
		If ImageSearch(foundX, foundY, cardLocation.topLeftX, cardLocation.topLeftY, cardLocation.bottomRightX, cardLocation.bottomRightY, "*1 " A_ScriptDir "\Images\Dota2-CardAnalyzer\Roles\" playerRole cardType ".png")
			return %playerRole%
	}
}

GetMods(ByRef modList, ByRef percent, cardLocation, cardType, playerRole) {
	modTypeList := ["CampsStacked", "CreepScore", "Deaths", "FirstBlood", "GPM", "Kills", "ObsWardsPlanted", "RoshanKills", "RunesGrabbed", "Stuns", "Teamfight", "TowerKills"]
	coreScoreList := [0, 1.2, 2.3, 0.9, 1.3, 2.9, 0, 0.9, 4.4, 3.5, 2.3, 3.4]
	offlaneScoreList := [0, 0, 0, 0.9, 0, 0, 0, 0, 4.4, 3.5, 2.3, 0]
	supportScoreList := [1.8, 0, 0, 0.9, 0, 0, 7, 0, 4.4, 3.5, 2.3, 0]
	cardScore := 0
	matches := 0
	
	For index, currentModType in modTypeList {
		If ImageSearch(foundX, foundY, cardLocation.topLeftX, cardLocation.topLeftY, cardLocation.bottomRightX, cardLocation.bottomRightY, "*30 " A_ScriptDir "\Images\Dota2-CardAnalyzer\Mods\" currentModType cardType ".png") {
			modList.Push(currentModType)
			modPercent := GetPercent(foundX, foundY, cardType)
			percent.Push(modPercent)
			
			StringLower, roleLower, playerRole
			cardScore := cardScore + (%roleLower%ScoreList[index] * (modPercent / 100))
			
			matches++
			
			If (cardType = "Silver" && matches > 2) || (cardType = "Gold" && matches > 4)
				break
		}
	}
	
	return cardScore
}

GetPercent(topX, topY, cardType) {
	percentList := ["5", "10", "15", "20", "25"]

	For indexPer, elementPer in percentList {
		currentPercent := percentList[indexPer]
		
		If ImageSearch(foundX, foundY, topX + 300, topY, topX + 400, topY + 25, "*40 " A_ScriptDir "\Images\Dota2-CardAnalyzer\Percents\" currentPercent cardType ".png")
			return %currentPercent%
	}
}

GenerateDebug(cardList) {
	messageString := ""
	
	For index, card in cardList {
		If index > 1
			messageString .= "`n"
		
		messageString .= "===== Card " index " =====`n`n"
		
		messageString .= "Card Type: " card.cardType "`n`n"
	
		messageString .= "Role: " card.playerRole "`n"
		
		If card.modList.Length() > 0
			messageString .= "`nFound the following mods:`n"
		
		For index2, element in card.modList {
			messageString .= card.modList[index2] ": " card.percent[index2] "%`n"
		}
		
		If card.modList.Length() > 0 {
			messageString .= "`n"
			messageString .= "Card Score: " TrimNumberStr(card.cardScore) "`n"
		}
	}
	
	return messageString
}

TrimNumberStr(num) {
	Loop, % StrLen(num) {
		stringright, tester, num, 2
		If (tester = ".0")
			break
		stringright, tester, num, 1
		If (tester = "0")
			stringtrimright, num, num, 1
	}
	
	return num
}