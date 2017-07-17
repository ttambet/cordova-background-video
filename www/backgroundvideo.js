var cordova = require('cordova');

var backgroundvideo = {
    start : function(filename, camera, successFunction, errorFunction) {
        camera = camera || 'back';
        cordova.exec(successFunction, errorFunction, 'backgroundvideo', 'start', [filename, camera]);
        window.document.body.style.opacity = .99;
        setTimeout(function () {
          window.document.body.style.opacity = 1;
        }, 23)
    },
    stop : function(successFunction, errorFunction) {
        cordova.exec(successFunction, errorFunction, 'backgroundvideo','stop', []);
    }
};

module.exports = backgroundvideo;
