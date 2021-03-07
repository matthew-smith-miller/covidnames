refreshInterval = setInterval(refreshCards, 2000);

function refreshCards() {
    if (document.getElementById("game_state").value == "display_game") {
        refreshAllObjects_Apex();
    }
}
function disableButtons(demoMode) {
    if (demoMode) {
        document.getElementById("new_game_btn").disabled = true;
        document.getElementById("leave_room_btn").disabled = true;
    }
}
function findPlayer() {
    input = document.getElementById("find_player_name").value;
    if (input != "") {
        findPlayer_Apex(input);
    } else {
        alert("Please enter a name");
    }
}
function createNewPlayer() {
    input = document.getElementById("new_player_name").value;
    if (input.includes(" ")) {
        alert("No spaces are allowed in player names");
    } else if (input == "") {
        alert("Please enter a name");
    } else {
        createNewPlayer_Apex(input);
    }
}
function showPlayerResult(playerResult) {
    if (playerResult != "Success") {
        alert(playerResult);
    }
}
function changeTeam(circle, clickedId, playerId, demoMode) {
    if (clickedId == playerId && demoMode) {
        changeTeam_Apex();
        if (circle.className.includes("red_team") == true) {
            circle.className = circle.className.replace("red_team","blue_team");
        } else if (circle.className.includes("blue_team") == true) {
            circle.className = circle.className.replace("blue_team","red_team");
        } else {
            circle.className += " blue_team";
        }
    }
}
function autotab(event, input) {
    if (input.id.substring(5) != "1") {
        if (event.keyCode == 8 && input.value.length == 0){
            document.getElementById("code_" + (parseInt(input.id.substring(5))-1).toString()).select();
        }
    }
    if (input.id.substring(5) != "8") {
        if (input.value.length == input.maxLength) {
            document.getElementById("code_" + (parseInt(input.id.substring(5))+1).toString()).select();
        }
    }
    if (input.id.substring(5) == "8") {
        if (input.value.length == input.maxLength) {
            searchSession();
        }
    }
}
function searchSession() {
    code = "";
    for (let i = 1; i < 9; i++) {
        code += document.getElementById("code_" + i).value;
        if (i == 4) {
            code += " ";
        }
    }
    searchViaInterface_Apex(code);
}
function revealColor(card) {
    console.log("in revealColor");
    touchCard_Apex(card.name);
    if (card.className.includes("Revealed") == false) {
        card.className += " Revealed";
    }
    overlay = document.getElementById("card-overlay-"+card.name);
    if (overlay.className.includes("Revealed") == false) {
        overlay.className += " Revealed";
    }
    img = document.getElementById("card-img-"+card.name);
    if (img.className.includes("Revealed") == false) {
        img.className += " Revealed";
    }
    document.getElementById("card-name-"+card.name).style = "display:none";
}
function showPopup(popupId) {
    document.getElementById(popupId).style="display:block";
    if (popupId == "new_game_popup") {
        populatePlayers();
    }
}
function hidePopup(popupId) {
    document.getElementById(popupId).style="display:none";
}
function populatePlayers() {
    clone_badges = document.getElementsByName("radio_badge_clone");
    length = clone_badges.length
    if (clone_badges.length > 0) {
        for (let i = 0; i < length; i++) {
            clone_badges[0].parentNode.removeChild(clone_badges[0]);
        }
    }
    player_badges = document.getElementsByName("player_badge");
    blue_radio_badge = document.getElementById("blue_radio_badge");
    red_radio_badge = document.getElementById("red_radio_badge");
    for (let i in player_badges) {
        if (player_badges[i].className.includes("blue_team")) {
            new_badge = blue_radio_badge.cloneNode(true);
            new_badge.style="display:flex";
            new_badge.setAttribute("name","radio_badge_clone");
            new_badge.id += "_" + player_badges[i].id.replace("player_badge_","");
            new_badge.childNodes[5].innerHTML = player_badges[i].childNodes[1].innerHTML;
            new_badge.childNodes[1].value = player_badges[i].id.replace("player_badge_","");
            blue_radio_badge.parentNode.insertBefore(new_badge, blue_radio_badge);
        }
        if (player_badges[i].className.includes("red_team")) {
            new_badge = red_radio_badge.cloneNode(true);
            new_badge.style="display:flex";
            new_badge.setAttribute("name","radio_badge_clone");
            new_badge.id += "_" + player_badges[i].id.replace("player_badge_","");
            new_badge.childNodes[5].innerHTML = player_badges[i].childNodes[1].innerHTML;
            new_badge.childNodes[1].value = player_badges[i].id.replace("player_badge_","")
            red_radio_badge.parentNode.insertBefore(new_badge, red_radio_badge);
        }
    }
}
function createNewGame() {
    blueValue = "";
    redValue = "";
    blueRadioButtons = document.getElementsByName("radio_blue_team");
    redRadioButtons = document.getElementsByName("radio_red_team");
    if (blueRadioButtons.length == 0) {
        blueValue = "no_players";
    }
    if (redRadioButtons.length == 0) {
        redValue = "no_players";
    }
    for (let i in blueRadioButtons) {
        if (blueRadioButtons[i].checked) {
            blueValue = blueRadioButtons[i].value;
            break;
        }
    }
    for (let i in redRadioButtons) {
        if (redRadioButtons[i].checked) {
            redValue = redRadioButtons[i].value;
            break;
        }
    }
    if (redValue != "" && blueValue != "") {
        hidePopup("new_game_popup");
        createNewGame_Apex(blueValue + "," + redValue);
        for (let i in blueRadioButtons) {
            blueRadioButtons[i].checked = false;
        }
        for (let i in redRadioButtons) {
            redRadioButtons[i].checked = false;
        }
    } else {
        alert("Please select a spymaster for both teams");
    }
}
function checkSpymasterCode(value) {
    hidePopup("enter_spymaster_popup")
    checkSpymasterCode_Apex(value);
}
function checkEnter(event, element) {
    if (event.keyCode == 13) {
        if (element.id == "enter_spymaster_input") {
            checkSpymasterCode(element.value);
        } else if (element.id == "new_game_input") {
            createNewGame(element.value);
        } else if (element.id == "find_player_name") {
            findPlayer();
        } else if (element.id == "new_player_name") {
            createNewPlayer();
        } else if (element.id == "image_set_code") {
            createNewSession(element.value);
        }
    }
}
function showName(element) {
    document.getElementById("card-name-"+element.id.replace("card-overlay-","")).style="display:block";
}
function hideName(element) {
    document.getElementById("card-name-"+element.id.replace("card-overlay-","")).style="display:none";
}
function demo_SpymasterView() {
    toggleSpymaster_Apex();
}
function demo_ResetCards() {
    resetCards_Apex();
}
function demo_HomePage() {
    window.open(
        "https://covidnames-developer-edition.na111.force.com/covidnames/", "_blank");
}