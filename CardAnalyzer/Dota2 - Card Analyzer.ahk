#NoEnv
SetBatchLines -1
ListLines Off
SendMode Input
SetWorkingDir %A_ScriptDir%

#Include xml.ahk

; TODO
; 1) Fix issue with unlimited number of recommendations occurring
; 2) Remove duplicate player listings from recommendations
; 3) Add error checking - validate number of mods found matches card type
; 4) Add cleaner handling of green cards for persistent storage (don't store blank score or mods)
; 5) Add edge-case handling for situations like where players are on the last card and try and save a stack, but it only saves that last card
; 6) Add processing of entire team list - maybe require manual changing between players?

$^1::
	IfWinExist Dota 2
	{
		WinActivate
		
		cardData := LoadData(PlayerStats, PlayerAvgFP, TeamSchedule)
		playerStats := PlayerStats
		playerAvgFp := PlayerAvgFP
		teamSchedule := TeamSchedule
		
		cardTypeList := ["Silver", "Gold", "Green"]
		cardList := {}
		
		cardLocation := GetCardLocation(cardTypeList)
		playerTeam := GetTeam(cardLocation)
		playerName := GetPlayer(cardLocation, playerTeam)
		
		Loop {
			modList := []
			percent := []
			
			card := {}
			card.playerTeam := playerTeam
			card.playerName := playerName
			card.cardType := GetCardType(cardTypeList, cardLocation)
			card.playerRole := GetRole(cardLocation, card.cardType)
			card.cardScore := GetMods(modList, percent, cardLocation, card.cardType, card.PlayerName, card.playerRole, card.playerTeam, playerStats, playerAvgFp)
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
		
		If cardList[1].playerTeam != "" {
			cardData := SaveCards(cardData, cardList)
		
			cardData.writeXML(A_ScriptDir "\CardData.xml")
			
			messageString := GenerateDebug(cardList)
			
			MsgBox %messageString%
		} else {
			MsgBox, "No card(s) found, please select a player and try again"
		}
	}
Return

$^2::
	IfWinExist Dota 2
	{
		WinActivate
		
		cardData := LoadData(PlayerStats, PlayerAvgFP, TeamSchedule)
		playerStats := PlayerStats
		playerAvgFp := PlayerAvgFP
		teamSchedule := TeamSchedule
		
		typeList := ["Core", "Offlane", "Support"]
		
		rankingCore := {}
		rankingOfflane := {}
		rankingSupport := {}
		
		InputBox, scheduleDate, "Enter Schedule Date", "Enter the date to analyze in MM/DD/YYYY format:"
		
		InputBox, roleChoice, "Enter Role Choice", "Enter the role you would like to analyze: Core`, Offlane`, or Support:"
		
		InputBox, rankingCount, "Enter Ranking Count", "Enter the number of top players to return for each role:"
		
		For teamIndex, teamNode in cardData.getChildren("Data", "element") {
			teamName := cardData.getText("//Team[" teamIndex "]/Name")
			For playerIndex, playerNode in cardData.getChildren("//Team[" teamIndex "]/Players", "element") {
				playerName := cardData.getText("//Team[" teamIndex "]/Players/Player[" playerIndex "]/Name")
				playerRole := cardData.getText("//Team[" teamIndex "]/Players/Player[" playerIndex "]/Position")
				
				For cardIndex, cardNode in cardData.getChildren("//Team[" teamIndex "]/Players/Player[" playerIndex "]/Cards", "element") {
					scoreBase := cardData.getText("//Team[" teamIndex "]/Players/Player[" playerIndex "]/Cards/Card[" cardIndex "]/Score")
					
					gamesPlayed := GetGamesPlayed(teamName, scheduleDate, teamSchedule)
					
					scoreAggregate := scoreBase * gamesPlayed
					
					ranking%playerRole% := UpdateRanking(ranking%playerRole%, playerName, teamName, scoreBase, scoreAggregate, rankingCount)
				}
			}
		}
		
		messageString := "====== Top " rankingCount " " roleChoice " Players ======`n`n"

		For objectIndex, rankingEntry in ranking%roleChoice% {
			messageString .= "= " objectIndex " =`n"
			messageString .= "Player Name: " rankingEntry.playerName "`n"
			messageString .= "Team Name: " rankingEntry.teamName "`n"
			messageString .= "Base Score: " rankingEntry.scoreBase "`n"
			messageString .= "Aggregate Score: " rankingEntry.scoreAggregate "`n`n"
		}
		
		MsgBox %messageString%
	}
Return

$^3::
	ExitApp
Return

ImageSearch(ByRef x, ByRef y, x1, y1, x2, y2, file) {
	ImageSearch, x, y, % x1, % y1, % x2, % y2, % file
	
	return !ErrorLevel
}

LoadData(ByRef PlayerStats, ByRef PlayerAvgFP, ByRef TeamSchedule) {
	If !FileExist("xml.ahk") {
		MsgBox, "xml.ahk is missing. This program will not work without this file. Please add this file to the program folder and restart the program."
		ExitApp
	}

	If FileExist("CardData.xml") {
		xmlFile := new xml()
		xmlFile.load("CardData.xml")
	} else {
		xmlFile := new xml("<Data/>")
		xmlFile.writeXML(A_ScriptDir "\CardData.xml")
	}
	
	FileCheckArray := []
	
	If FileExist("PlayerStats.xml") {
		playerStats := new xml()
		playerStats.load("PlayerStats.xml")
		PlayerStats := playerStats
	} else {
		FileCheckArray.Push("PlayerStats.xml")
	}
	
	If FileExist("PlayerAvgFP.xml") {
		playerAvgFp := new xml()
		playerAvgFp.load("PlayerAvgFP.xml")
		PlayerAvgFP := playerAvgFp
	} else {
		FileCheckArray.Push("PlayerAvgFP.xml")
	}
	
	If FileExist("TeamSchedule.xml") {
		teamSchedule := new xml()
		teamSchedule.load("TeamSchedule.xml")
		TeamSchedule := teamSchedule
	} else {
		FileCheckArray.Push("TeamSchedule.xml")
	}
	
	If FileCheckArray.Length() > 0 {
		messageString := "*** WARNING ***`n`nThe following data files are missing from the program folder, which means that the program cannot function properly. Please add the missing data files and restart the program.`n"
	
	
		For index, file in FileCheckArray {
			messageString .= "`n- " FileCheckArray[index]
		}
		
		MsgBox %messageString%
		ExitApp
	}
	
	return xmlFile
}

LoadPlayerStats() {
	If FileExist("PlayerStats.xml") {
		xmlFile := new xml()
		xmlFile.load("PlayerStats.xml")
	} else {
		MsgBox, "No PlayerStats.xml file found. This file is necessary and the program cannot function without it. Please add a PlayerStats.xml file and re-start the program."
		ExitApp
	}
	
	return xmlFile
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

GetTeam(cardLocation) {
	teamList := ["EvilGeniuses", "Fnatic", "InvictusGaming", "Mineski", "Newbee", "OG", "OpTicGaming", "paiNGaming", "PSGLGD", "TeamLiquid", "TeamSecret", "TeamSerenity", "TNCPredator", "VGJStorm", "VGJThunder", "ViciGaming", "VirtusPro", "Winstrike"]
	
	For index, currentTeam in teamList {
		If ImageSearch(topLeftX, topLeftY, cardLocation.topLeftX, cardLocation.topLeftY, cardLocation.bottomRightX, cardLocation.bottomRightY, "*5 " A_ScriptDir "\Images\Dota2-CardAnalyzer\Teams\" currentTeam ".png")
			return %currentTeam%
	}
}

GetPlayer(cardLocation, playerTeam) {
	EvilGeniuses := ["Cr1t-", "Fly", "rtzYBa", "s4", "SumaiL"]
	Fnatic := ["Abed", "DJ", "EternaLEnVy", "pieliedie", "Universe"]
	InvictusGaming := ["Agressif", "BoBoKa", "Q", "Srf", "Xxs"]
	Mineski := ["iceiceice", "Jabz", "Moonn", "Mushi", "ninjaboogie"]
	Newbee := ["Faith", "kaka", "kpii", "Moogy", "Sccc"]
	OG := ["ana", "BigDaddyN0tail", "Ceb", "JerAx", "Topson"]
	OpTicGaming := ["33", "CCnC", "Pajkatt", "Peterpandam", "zai"]
	paiNGaming := ["Duster", "hFnk3M", "Kingrd", "tavo", "w33"]
	PSGLGD := ["Ame", "Chalice", "fy", "SomnusM", "xNova"]
	TeamLiquid := ["Gh", "KuroKy", "MATUMBAMAN", "MinD_ContRol", "Miracle-"]
	TeamSecret := ["Ace", "Fata", "MidOne", "Puppey", "YapzOr"]
	TeamSerenity := ["Pyw", "XCJ", "XinQ", "zhizhizhi", "Zyd"]
	TNCPredator := ["Armel", "Kuku", "Raven", "SamH", "Tims"]
	VGJStorm := ["MSS-", "Resolut1on", "Sneyking", "SVG", "YS"]
	VGJThunder := ["ddc", "Fade", "Freeze", "Sylar", "Yang"]
	ViciGaming := ["eLeVen", "Fenrir", "LaNm", "Ori", "Paparazi"]
	VirtusPro := ["9pasha", "No[o]ne-", "RAMZES666", "RodjER", "Solo"]
	Winstrike := ["ALWAYSWANNAFLY", "Iceberg", "Nofear", "nongrata", "Silent"]
	
	For index, currentPlayer in %playerTeam% {
		If ImageSearch(topLeftX, topLeftY, cardLocation.topLeftX, cardLocation.topLeftY, cardLocation.bottomRightX, cardLocation.bottomRightY, "*5 " A_ScriptDir "\Images\Dota2-CardAnalyzer\Players\" playerTeam "\" currentPlayer ".png")
			return %currentPlayer%
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

GetMods(ByRef modList, ByRef percent, cardLocation, cardType, playerName, playerRole, playerTeam, playerStats, playerAvgFp) {
	modTypeList := ["CampsStacked", "CreepScore", "Deaths", "FirstBlood", "GPM", "Kills", "ObsWardsPlanted", "RoshanKills", "RunesGrabbed", "Stuns", "Teamfight", "TowerKills"]
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
	
	cardScore := GetCardScore(modList, percent, modTypeList, playerName, playerRole, playerTeam, playerStats, playerAvgFp)
	
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

GetCardScore(modList, percent, modTypeList, playerName, playerRole, playerTeam, playerStats, playerAvgFp) {
	cardScore := 0

	If PlayerExists(playerStats, playerName, playerRole, 0, playerIndex, "PlayerStats") {
		For index, currentModType in modTypeList {
			For index2, currentModList in modList {
				If (currentModList = currentModType) {
					cardScore := cardScore + (playerStats.getText("//Player[" playerIndex "]/Mods/" currentModType) * (1 + (percent[index2] / 100)))
					continue 2
				}
			}
			cardScore := cardScore + playerStats.getText("//Player[" playerIndex "]/Mods/" currentModType)
		}
	} Else {
		TeamExists(playerAvgFp, playerTeam, teamIndex, "PlayerAvgFP")
		TeamExists(playerAvgFp, "Roles", roleTeamIndex, "PlayerAvgFP")
		PlayerExists(playerAvgFp, playerName, playerRole, teamIndex, playerIndex2, "PlayerAvgFP")
		PlayerExists(playerAvgFp, playerRole, playerRole, roleTeamIndex, rolePlayerIndex, "PlayerAvgFP")
		
		For index, currentModType in modTypeList {
			For index2, currentModList in modList {
				If (currentModList = currentModType) {
					cardScore := cardScore + (playerStats.getText("//Player[" playerIndex "]/Mods/" currentModType) * (1 + (percent[index2] / 100)))
					continue 2
				}
			}
			cardScore := cardScore + playerStats.getText("//Player[" playerIndex "]/Mods/" currentModType)
		}
		
		cardScore := cardScore * (playerAvgFp.getText("//Team[" teamIndex "]/Players/Player[" playerIndex2 "]/AvgFP") / playerAvgFp.getText("//Team[" roleTeamIndex "]/Players/Player[" rolePlayerIndex "]/AvgFP"))
	}
	
	return cardScore
}

GenerateDebug(cardList) {
	messageString := "Name: " cardList[1].playerName "`n`nTeam: " cardList[1].playerTeam "`n`nRole: " cardList[1].playerRole "`n`n"
	
	For index, card in cardList {
		If index > 1
			messageString .= "`n"
		
		messageString .= "===== Card " index " =====`n`n"
		
		messageString .= "Card Type: " card.cardType "`n`n"
		
		If card.modList.Length() > 0
			messageString .= "Found the following mods:`n"
		
		For index2, element in card.modList {
			messageString .= card.modList[index2] ": " card.percent[index2] "%`n"
		}

		messageString .= "`n"
		messageString .= "`nCard Score: " TrimNumberStr(card.cardScore) "`n"
	}
	
	return messageString
}

SaveCards(xmlData, cardList) {
	teamIndex := 1
	playerIndex := 1

	If !TeamExists(xmlData, cardList[1].playerTeam, teamIndex, "CardData") {
		xmlData.addElement("Team", "Data")
		xmlData.addElement("Name", "//Team[" teamIndex "]", cardList[1].playerTeam)
		xmlData.addElement("Players", "//Team[" teamIndex "]")
	}
	
	If !PlayerExists(xmlData, cardList[1].playerName, cardList[1].playerRole, teamIndex, playerIndex, "CardData") {
		xmlData.addElement("Player", "//Team[" teamIndex "]/Players")
		xmlData.addElement("Name", "//Team[" teamIndex "]/Players/Player[" playerIndex "]", cardList[1].playerName)
		xmlData.addElement("Position", "//Team[" teamIndex "]/Players/Player[" playerIndex "]", cardList[1].playerRole)
		xmlData.addElement("Cards", "//Team[" teamIndex "]/Players/Player[" playerIndex "]")
	} Else {
		deleteNode := xmlData.selectSingleNode("//Team[" teamIndex "]/Players/Player[" playerIndex "]/Cards")
		deleteNode.ParentNode.RemoveChild(deleteNode)
		xmlData.addElement("Cards", "//Team[" teamIndex "]/Players/Player[" playerIndex "]")
	}
	
	For index, card in cardList {
		xmlData.addElement("Card", "//Team[" teamIndex "]/Players/Player[" playerIndex "]/Cards")
		xmlData.addElement("Type", "//Team[" teamIndex "]/Players/Player[" playerIndex "]/Cards/Card[" index "]", card.cardType)
		xmlData.addElement("Score", "//Team[" teamIndex "]/Players/Player[" playerIndex "]/Cards/Card[" index "]", TrimNumberStr(card.cardScore))
		xmlData.addElement("Mods", "//Team[" teamIndex "]/Players/Player[" playerIndex "]/Cards/Card[" index "]")
		
		For index2, element in card.modList {
			xmlData.addElement("Mod", "//Team[" teamIndex "]/Players/Player[" playerIndex "]/Cards/Card[" index "]/Mods")
			xmlData.addElement("Type", "//Team[" teamIndex "]/Players/Player[" playerIndex "]/Cards/Card[" index "]/Mods/Mod[" index2 "]", card.modList[index2])
			xmlData.addElement("Percent", "//Team[" teamIndex "]/Players/Player[" playerIndex "]/Cards/Card[" index "]/Mods/Mod[" index2 "]", card.percent[index2])
		}
	}
	
	return xmlData
}

TeamExists(xmlData, playerTeam, ByRef teamIndex, fileType) {
	If (fileType = "CardData") {
		For index, node in xmlData.getChildren("Data", "element") {
			If xmlData.getText("//Team[" index "]/Name") = playerTeam {
				teamIndex := index
				return true
			}
			
			teamIndex := ++index
		}

		return false
	} Else If (fileType = "PlayerAvgFP") {
		For index, node in xmlData.getChildren("Teams", "element") {
			If xmlData.getText("//Team[" index "]/Name") = playerTeam {
				teamIndex := index
				return true
			}
		}

		return false
	}
}

PlayerExists(xmlData, playerName, playerRole, teamIndex, ByRef playerIndex, fileType) {
	If (fileType = "CardData") {
		For index, node in xmlData.getChildren("//Team[" teamIndex "]/Players", "element") {
			If xmlData.getText("//Team[" teamIndex "]/Players/Player[" index "]/Name") = playerName {
				playerIndex := index
				return true
			}
			
			playerIndex := ++index
		}
		
		return false
	} Else If (fileType = "PlayerStats") {
		For index, node in xmlData.getChildren("Players", "element") {
			If xmlData.getText("//Player[" index "]/Name") = playerName {
				playerIndex := index
				return true
			} Else If xmlData.getText("//Player[" index "]/Name") = playerRole {
				playerIndex := index
				return false
			}
		}
		
		return true
	} Else If (fileType ="PlayerAvgFP") {
		For index, node in xmlData.getChildren("//Team[" teamIndex "]/Players", "element") {
			If xmlData.getText("//Team[" teamIndex "]/Players/Player[" index "]/Name") = playerName {
				playerIndex := index
				return true
			}
		}
		
		return false
	}
}

GetGamesPlayed(teamName, scheduleDate, teamSchedule) {
	For teamIndex, teamNode in teamSchedule.getChildren("Teams", "element") {
		If (teamSchedule.getText("//Team[" teamIndex "]/Name") = teamName) {
			For dayIndex, dayNode in teamSchedule.getChildren("//Team[" teamIndex "]/Days", "element") {
				If (teamSchedule.getText("//Team[" teamIndex "]/Days/Day[" dayIndex "]/Date") = scheduleDate)
					return teamSchedule.getText("//Team[" teamIndex "]/Days/Day[" dayIndex "]/NumGames")
			}
		}
	}
}

UpdateRanking(rankingObject, playerName, teamName, scoreBase, scoreAggregate, rankingCount) {
	player := {}
	player.playerName := playerName
	player.teamName := teamName
	player.scoreBase := scoreBase
	player.scoreAggregate := scoreAggregate
	
	For index, playerRecord in rankingObject {
		If (player.scoreAggregate > playerRecord.scoreAggregate) {
			rankingObject.InsertAt(index, player)
			return rankingObject
		}
	}
	
	rankingObject.Push(player)
	
	return rankingObject
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