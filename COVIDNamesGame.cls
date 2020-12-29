public with sharing class COVIDNamesGame {

    public List<Game_Card__c> gameCards {get; set;}
    public Game__c game {get; set;}
    public Session__c session {get;set;}
    public String gameState {get;set;}
    public String viewMode {get;set;}
    public String refreshMode {get;set;}
    public Boolean demoMode {get;set;}
    public String inputSessionName {get;set;}
    public Id touchedCardId {get;set;}
    public String newGameCode {get;set;}
    public String enteredCode {get;set;}
    public Integer blueCardsRemaining {get;set;}
    public Integer redCardsRemaining {get;set;}
    public Player__c player {get;set;}
    public List<Player__c> bluePlayers;
    public List<Player__c> redPlayers;
    public String playerNameInput {get;set;}
    public String playerResult {get;set;}
    public String displayPopupNewGame {get;set;}
    public String displayPopupLeaveRoom {get;set;}
    public String imageSetCode {get;set;}
    public Set<String> imageSetCodes;
    public Map<Id,Game_Card__c> gameCardsMap;
    Map<String,List<String>> imageMap;
    
    public COVIDNamesGame() {
        
        gameState = 'intro_screen';
        viewMode = 'player';
        refreshMode = 'active';
        demoMode = false;
        player = new Player__c();
        bluePlayers = new List<Player__c>();
        redPlayers = new List<Player__c>();
        session = new Session__c();
        game = new Game__c();
        gameCards = new List<Game_Card__c>();
        gameCardsMap = new Map<Id,Game_Card__c>();
        imageMap = new Map<String,List<String>>();
        blueCardsRemaining = 0;
        redCardsRemaining = 0;
        displayPopupNewGame = 'display:none';
        displayPopupLeaveRoom = 'display:none';
        imageSetCode = '';
        imageSetCodes = new Set<String>{'uptown','miller'};
        
        if(ApexPages.currentPage().getParameters().get('demo') == 'true') {
            demoMode = true;
            playerNameInput = 'DemoPlayer';
            findPlayer();
        } else {
            demoMode = false;
        }
    }
    
    public void searchViaInterface() {
        session = findSessionByName(inputSessionName);
        if (session != null) {
            if (session.Games__r.isEmpty() == false) {
                game = session.Games__r[0];
                gameCards = getExistingGameCards(game.Id);
                countCardsRemaining();
                gameCardsMap = new Map<Id,Game_Card__c>(gameCards); 
            }
            if (player.Id != null) {
                if (player.Session__c == null) {
                    player.Session__c = session.Id;
                    player.Team__c = flipCoin().toLowercase() + '_team';
                    update player;
                }
            }
            gameState = 'display_game';
            refreshAllObjects();
        }
    }
    
    public void refreshAllObjects() {                
        if (player != null) {
            findPlayerByName(player.Name);
            if (player.isSpymaster__c) {
                viewMode = 'spymaster';
            } else {
                viewMode = 'player';
            }
        }        
        if (session != null) {
            session = findSessionById(session.Id);
            if (session != null) {
                if (session.Games__r.isEmpty() == false) {
                    game = session.Games__r[0];
                    refreshCards();
                }
                splitPlayersByColor();
            }
        } 
    }
    
    public void refreshCards() {
        gameCards = getExistingGameCards(game.Id);
        gameCardsMap = new Map<Id,Game_Card__c>(gameCards);
        countCardsRemaining();
    }
    
    public void countCardsRemaining() {
        blueCardsRemaining = 0;
        redCardsRemaining = 0;
        for (Game_Card__c gameCard : gameCards) {
            if (gameCard.Revealed__c != 'Revealed') {
                if (gameCard.Assigned_Color__c == 'Blue') {
                    blueCardsRemaining++;
                } else if (gameCard.Assigned_Color__c == 'Red') {
                    redCardsRemaining++;
                }
            }
        }
    }
    
    public Session__c findSessionByName(String searchName) {
        List<Session__c> sessions = [SELECT
                                        Id,
                                        Name,
                                        Cards_Used__c,
                                        Image_Set__c,
                                        Code__c,
                                        (SELECT Id, Spymaster_Code__c, Color__c from Games__r WHERE Status__c = 'Active' ORDER BY CreatedDate DESC),
                                        (SELECT Id, Name, isSpymaster__c, Team__c FROM Players__r ORDER BY Team__c NULLS LAST)
                                    FROM
                                        Session__c
                                    WHERE
                                        Code__c = :searchName
                                    LIMIT 1];
        if (sessions.size() == 1) {
            return sessions[0];
        }
        else {
            return null;
        }                   
    }
    
    public Session__c findSessionById(String searchId) {
        List<Session__c> sessions = [SELECT
                                        Id,
                                        Name,
                                        Cards_Used__c,
                                        Image_Set__c,
                                        Code__c,
                                        (SELECT Id, Spymaster_Code__c, Color__c FROM Games__r WHERE Status__c = 'Active' ORDER BY CreatedDate DESC),
                                        (SELECT Id, Name, isSpymaster__c, Team__c FROM Players__r ORDER BY Team__c NULLS LAST)
                                    FROM
                                        Session__c
                                    WHERE
                                        Id = :searchId
                                    LIMIT 1];
        if (sessions.size() == 1) {
            return sessions[0];            
        }
        else {
            return null;
        }                  
    }
    
    public void createNewSession() {
        session = new Session__c();
        session.Code__c = generateSessionCode();
        System.Debug('%%%' + imageSetCodes);
        System.Debug('%%%' + imageSetCode);
        if (imageSetCodes.contains(imageSetCode)) {
            session.Image_Set__c = imageSetCode;
        }
        insert session;
        gameState = 'display_game';
        if (player.Id != null) {
            player.Session__c = session.Id;
            player.Team__c = flipCoin().toLowercase() + '_team';
            update player;
        }
        refreshAllObjects();
    }
    
    public void createNewGame() {
        if (session.Id != null) {
            if (game.Id != null) {
                endGame();
            }
            game = new Game__c(Session__c = session.Id, Color__c = flipCoin());
            if (newGameCode != null) {
                List<String> playerIds = newGameCode.split(',');
                setSpymasters(playerIds);
            }
            insert game;
            drawNewGameCards();
            refreshAllObjects();
        }
    }
    
    public void endGame() {
        if(game != null) {
            game.Status__c = 'Completed';
            if (session.Cards_Used__c == null) {
                session.Cards_Used__c = '';
            }
            if (session.Cards_Used__c != '') {
                session.Cards_Used__c += ',';
            }
            Integer count = 0;
            while (count < gameCards.size()) {
                session.Cards_Used__c += gameCards[count].Name;
                count++;
                if (count < gameCards.size()) {
                    session.Cards_Used__c += ',';
                }
            }
            delete gameCards;
            update game;
            update session;
        }
    }
    
    public List<Game_Card__c> getExistingGameCards(Id gameId) {
        return [SELECT
                    Id,
                    Name,
                    Assigned_Color__c,
                    Image__c,
                    Revealed__c                    
                FROM
                    Game_Card__c
                WHERE
                    Game__c = :gameId
                LIMIT 25];
    }
    
    public void drawNewGameCards() {
        gameCards = new List<Game_Card__c>();
        List<Decimal> randNums = new List<Decimal>();
        Map<Decimal,String> randNumsToCards = new Map<Decimal,String>();
        
        if (session != null && session.Id != null && game != null && game.Id != null) {
            Set<String> cardsUsedSet = new Set<String>();
            if (session.Cards_Used__c != null) {
                List<String> cardsUsed = session.Cards_Used__c.split(',');
                cardsUsedSet.addAll(cardsUsed);
            }
            List<Configuration__c> configurations = [
                SELECT
                    Id,
                    Content__c
                FROM
                    Configuration__c
                WHERE
                    Name = 'cards'];
            
            if (configurations.size() > 0) {
                if (configurations[0].Content__c != null) {
                    List<String> cardDeck = configurations[0].Content__c.split(',');
                    for(String card : cardDeck) {
                        if(!cardsUsedSet.contains(card)) {
                            Decimal randNum = Math.random();
                            randNums.add(randNum);
                            randNumsToCards.put(randNum,card);
                        }
                    }
                    randNums.sort();
                    for (Integer i = 0; i < randNums.size(); i++) {
                        gameCards.add(new Game_Card__c(Game__c = game.Id, Name = randNumsToCards.get(randNums[i])));
                        if (i == 24) {
                            break;
                        }
                    } 
                    assignColors(gameCards);
                    insert gameCards; 
                }
            }              
        }
    }
    
    public void assignColors(List<Game_Card__c> gameCardsToColor) {
        String currentColor = 'Blue';
        Decimal randNum = 0;
        List<Decimal> randNums = new List<Decimal>();
        Map<Decimal,String> randNumsToColors = new Map<Decimal,String>();
        for(Integer i = 0; i < 25; i++) {
            randNum = Math.random();
            randNums.add(randNum);
            randNumsToColors.put(randNum,currentColor);
            if (i == 7) {
                currentColor = 'Red';
            }
            if (i == 15) {
                currentColor = 'Bystander';
            }
            if (i == 22) {
                currentColor = 'Assassin';
            }
            if (i == 23) {
                //We are just assuming this exists and is not null -- make safer
                currentColor = game.Color__c;
            }
        }
        randNums.sort();
        for (Integer i=0; i < gameCardsToColor.size(); i++) {
            gameCardsToColor[i].Assigned_Color__c = randNumsToColors.get(randNums[i]);
            buildImageMap();
            if (imageMap.get(gameCardsToColor[i].Assigned_Color__c.toLowerCase()) != null &&
                imageMap.get(gameCardsToColor[i].Assigned_Color__c.toLowerCase()).size() > 0) {
                gameCardsToColor[i].Image__c = 
                    imageMap.get(gameCardsToColor[i].Assigned_Color__c.toLowerCase())[(Math.random() *
                    imageMap.get(gameCardsToColor[i].Assigned_Color__c.toLowerCase()).size()).intValue()];
            }
        }
    }
   
    
    public void buildImageMap() {
        if(session != null && session.Image_Set__c != null) {
            List<StaticResource> staticResources = [
                SELECT
                    Id,
                    Name
                FROM
                    StaticResource
                WHERE
                    Name LIKE :session.Image_Set__c + '_%'];
            for (StaticResource staticResource : staticResources) {
                if (imageMap.get(staticResource.Name.substringBetween('_')) == null) {
                    imageMap.put(staticResource.Name.substringBetween('_'), new List<String>{staticResource.Name});
                }
                else {
                    imageMap.get(staticResource.Name.substringBetween('_')).add(staticResource.Name);
                }
            }
        }
    }
    
    public string flipCoin() {
        String winner = 'Red';
        if (Math.floor(Math.random()*10) >= 5) {
            winner = 'Blue';
        }
        return winner;
    } 
    
    public void touchCard() {
        Game_Card__c touchedCard = gameCardsMap.get(touchedCardId);
        if (touchedCard != null) {
            touchedCard.Revealed__c = 'Revealed';
            try {
                update touchedCard;
            } catch (System.DmlException ex) {
                System.debug(ex);
            }
                
            if (touchedCard.Assigned_Color__c == 'Blue') {
                blueCardsRemaining--;
            }
            else if (touchedCard.Assigned_Color__c == 'Red') {
                redCardsRemaining--;
            }
        }
    }
    
    public PageReference refreshScreen() {
        refreshAllObjects();
        return null;
    }
    
    public void checkSpymasterCode() {
        System.Debug(enteredCode);
        if (enteredCode == game.Spymaster_Code__c) {
            viewMode = 'spymaster';
        }
    }
    
    public void exitSpymasterMode() {
        viewMode = 'player';
    }
    
    public String generateSessionCode() {
        String firstWord = '';
        String secondWord = '';
        List<String> sourceWords = new List<String>();
        List<Configuration__c> configurations = [
            SELECT
                Id,
                Content__c
            FROM
                Configuration__c
            WHERE
                Name = 'session_code'];
        
        if (configurations.size() > 0) {
            sourceWords = configurations[0].Content__c.split(',');
            Boolean noDuplicatesFound = false;
            while (!noDuplicatesFound) {
                firstWord = sourceWords[(Math.random() * sourceWords.size()).intValue()];
                secondWord = sourceWords[(Math.random() * sourceWords.size()).intValue()];
                List<Session__c> existingSessions = [
                        SELECT
                            Id
                        FROM
                            Session__c
                        WHERE
                            Code__c = :(firstWord + secondWord)];
                if (existingSessions.size() == 0) {
                    noDuplicatesFound = true;
                }
            }
        }
        return firstWord + ' ' + secondWord;
    }
    public void findPlayer() {
        findPlayerByName(playerNameInput);
        if (player.Id != null) {
            if (player.Session__c != null) {
                inputSessionName = player.Session__r.Code__c;
                searchViaInterface();
            }
            else {
                gameState = 'logged_in';
            }
        }
    }
    public void findPlayerByName(String playerName) {
        playerResult = '';
        List<Player__c> players = [
            SELECT
                Id,
                Name,
                Team__c,
                isSpymaster__c,
                Session__c,
                Session__r.Code__c  
            FROM
                Player__c
            WHERE
                Name = :playerName
            ORDER BY
                CreatedDate DESC];
        if (players.size() > 0) {
            player = players[0];
            playerResult = 'Success';
        }
        else {
            playerResult = 'Player name does not exist';
        }
    }
    public void createNewPlayer() {
        playerResult = '';
        List<Player__c> existingPlayers = [
            SELECT
                Id
            FROM
                Player__c
            WHERE
                Name = :playerNameInput];
        if (existingPlayers.size() == 0) {
            player.Name = playerNameInput;
            player.Session__c = session.Id;
            insert player;
            gameState = 'logged_in';
            playerResult = 'Success';
        } else {
            playerResult = 'Player name already exists; choose a new one';
        }      
    }
    
    public void changeTeam() {
        if (player.Team__c == 'blue_team') {
            player.Team__c = 'red_team';
        } else if (player.Team__c == 'red_team') {
            player.Team__c = 'blue_team';
        }
        else {
            player.Team__c = 'blue_team';
        }
        update player;
        refreshAllObjects();
    }
    
    public void splitPlayersByColor() {
        bluePlayers = new List<Player__c>();
        redPlayers = new List<Player__c>();
        for (Player__c player : session.Players__r) {
            if (player.Team__c == 'blue_team') {
                bluePlayers.add(player);
            } else if (player.Team__c == 'red_team') {
                redPlayers.add(player);
            }
        }
        System.debug(bluePlayers);
    }
    
    public List<Player__c> getBluePlayers() {
        return bluePlayers;
    }
    public List<Player__c> getRedPlayers() {
        return redPlayers;
    }
    public void setSpymasters(List<String> playerIds) {
        Set<String> playerIdSet = new Set<String>(playerIds);
        for (Player__c playerToCheck : session.Players__r) {
            if (playerIdSet.contains(playerToCheck.Id)) {
                playerToCheck.isSpymaster__c = true;
            } else {
                playerToCheck.isSpymaster__c = false;
            }
        }
        update session.Players__r;
    }
    public void leaveRoom() {
        player.Session__c = null;
        player.Team__c = '';
        player.isSpymaster__c = false;
        update player;
        session = new Session__c();
        game = new Game__c();
        gameCards = new List<Game_Card__c>();
        gameState = 'logged_in';
    }
    public void toggleSpymaster() {
        player.isSpymaster__c = !player.isSpymaster__c;
        update player;
    }
    public void resetCards() {
        for (Game_Card__c gameCard : gameCards) {
            gameCard.Revealed__c = '';
        }
        update gameCards;
    }
}
