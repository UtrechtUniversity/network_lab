// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket,
// and connect at the socket path in "lib/web/endpoint.ex".
//
// Pass the token on params as below. Or remove it
// from the params if you are not using authentication.
import {Socket} from "phoenix"

//let socket = new Socket("/socket", {params: {token: window.userToken}})
//let socket = new Socket("/socket", {})

var ProgressBar = require('./progressbar.js')


let socket = null;
let userId = window.currentUserId;
let authToken = window.authToken;
let connectAdmin = window.connectAdmin;
let userNotConnected = window.userNotConnected;

// if there is aan authToken we try to connect with a socket
if (authToken) {

    let socket = new Socket("/auth_socket", { params: { token: authToken }})
    //socket.onOpen(() => console.log('socket connected'))
    socket.onOpen(() => true)

    // ===============================
    //          USER CHANNEL
    // ===============================
    if (userId && userId != 'false') {

        let channel = socket.channel("user:" + userId);
        //console.log("connected to user");

        // open channel
        channel.join()
            .receive("ok", resp => { console.log("Joined the user channel") })
            .receive("error", resp => { console.log("Unable to join user channel", resp) })

        // receiving messages
        channel.on('incoming_shared_message', function(message) {
            let payload = message.contents;

            let messages_list = document.querySelector('ul#undecided-messages-list');
            if (messages_list) {
                messages_list.insertAdjacentHTML('beforeend', payload);
            }
        });

        // this is for the waiting area/page
        channel.on('reveal_instructions', function(message) {

            // remove waiting for subjects pane straight away
            let waitingForPane = document.querySelector('section#queue-status');
            if (waitingForPane) {
                waitingForPane.style.display = 'none';
            }

            let condition_1 = message.condition_1;
            let condition_2 = message.condition_2;

            // reveal all stuff that's related to condition_1
            let elements = document.getElementsByClassName(condition_1);
            for (var i = 0; i < elements.length; i++) {
                elements[i].style.display = 'block';
            }
            // and reveal all stuff that's related to condition_2
            elements = document.getElementsByClassName(condition_2);
            for (var i = 0; i < elements.length; i++) {
                elements[i].style.display = 'block';
            }

            // and run the progress bar
            let finished = function() {
                let button = document.querySelector('div.go-button a#continue.button');
                if (button) {
                    // and click on the link
                    button.click();
                }
            }
            let startAt = Math.floor(Date.now()/1000);
            window.run_progress_bar(startAt, 30, '#00ff00', finished);

        });

        // this is for finishing
        channel.on('finish', function(message) {
            // click on the hidden finish button
            let button = document.querySelector('a#exit.button');
            if (button) {
                // and click on the link
                button.click();
            }
        });
    }


    // ===============================
    //         WAITING CHANNEL
    // ===============================
    if (userNotConnected && connectAdmin != "true") {

        let channel = socket.channel("waiting_channel");

        // open channel
        channel.join()
            .receive("ok", resp => { console.log("Joined the waiting channel") })
            .receive("error", resp => { console.log("Unable to join waiting channel", resp) })

        // receive updates
        channel.on('update', function(message) {

            // if we have 0 people in the queue, we're about to start, remove the status
            if (document.querySelector('section#queue-status')) {
                if (message.waiting_for === 0) {
                    document.querySelector('section#queue-status').remove();
                } else {
                    document.querySelector('span#queue-status').innerHTML = message.waiting_for;
                }
            }
            
        });
    }




    // ===============================
    //          ADMIN CHANNEL
    // ===============================
    if (connectAdmin == "true") {

        // init channel
        let channel = socket.channel("admin_channel");

        // open channel
        channel.join()
            .receive("ok", resp => { console.log("Joined the admin channel") })
            .receive("error", resp => { console.log("Unable to join admin channel", resp) })

        // receive updates
        channel.on('update', function (message) {

            let payload = message.payload
            // ensures payload is an array
            if (!Array.isArray(payload)) {
                payload = [payload];
            }

            // loop over payload
            payload.forEach((item, _index, _element) => {
                let selector = item.selector;
                let contents = item.contents

                let elem = document.querySelector(selector)
                if (elem != null) {
                    elem.innerHTML = contents;
                }
            });

        });
    }

    socket.connect();

}

export default socket;