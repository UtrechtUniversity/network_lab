// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative paths, for example:
import socket from "./socket"


// This is for the progression bar
// https://kimmobrunfeldt.github.io/progressbar.js/
var ProgressBar = require('./progressbar.js');


// This is for trying to avoid history-button-abuse
history.pushState(null, document.title, location.href);
window.addEventListener('popstate', function(event) {
    history.pushState(null, document.title, location.href);
});



window.run_progress_bar = function(startsAt, duration, color, finish_callback) {

    /*
    // This is basically: when did we start, what is the current time, when should we stop.
    // Divide the progression-wrapper width into 2 depending on how much time has passed, etc
    // Set the width of the past-div and future div and set a progressbar on both, the past bar
    // has duration 0 so we have it immediately, the future one is animated.
    */

    // get width of wrapper
    let wrapper = document.getElementById('progress-bar-wrapper');
    let pastBar = document.getElementById('progress-bar-past');
    let futureBar = document.getElementById('progress-bar-future');

    // clean any svg's if necessary
    while (pastBar.hasChildNodes()) {  
        pastBar.removeChild(pastBar.firstChild);
    }
    while (futureBar.hasChildNodes()) {  
        futureBar.removeChild(futureBar.firstChild);
    }

    let width = wrapper.offsetWidth;

    let startedAt = parseInt(startsAt);
    let currentTime = Math.floor(Date.now()/1000);
    let endsAt = startedAt + duration;

    let total = endsAt - startedAt;
    let past = currentTime - startedAt;
    // stop keep on groing after duration
    if (currentTime > endsAt) {
        past = endsAt - startedAt;
    }
    let future = total - past;

    let pastWidth = Math.floor((width * past) / total);
    let futureWidth = width - pastWidth;

    // set past-bar width
    pastBar.style.width = pastWidth + 'px'

    // set future-bar width
    futureBar.style.width = futureWidth + 'px'
    futureBar.style.marginLeft = pastWidth + 'px'

    // parameters
    let params = {
        strokeWidth: 4,
        easing: 'linear',
        duration: 0,
        color: color,
        trailColor: '#eee',
        trailWidth: 1,
        svgStyle: {width: '100%', height: '100%'}
    }

    let pastAnim = new ProgressBar.Line('#progress-bar-past', params);
    pastAnim.animate(1);

    params.duration = future * 1000;
    let futureAnim = new ProgressBar.Line('#progress-bar-future', params);
    futureAnim.animate(1, finish_callback);

}



// disable decisions buttons 
if (document.getElementById("decision-form")) {
    setTimeout (function() {
        let buttons = document.getElementsByClassName("decision-button");
        for(var i = 0; i < buttons.length; i++) {
            buttons[i].disabled = false;
        }
    }, 3000);
}

// window.onload = function () {
//     // This is for trying to avoid history-button-abuse
//     history.pushState(null, document.title, location.href);
//     window.addEventListener('popstate', function(event) {
//         history.pushState(null, document.title, location.href);
//     });
// }

