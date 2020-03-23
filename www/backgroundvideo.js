var cordova = require('cordova');

var backgroundvideo = {
    start : function(filename, camera, x, y, width, height, successFunction, errorFunction) {
        camera = camera || 'back';
        cordova.exec(successFunction, errorFunction, 'backgroundvideo', 'start', [filename, camera, x, y, width, height]);
        window.document.body.style.opacity = .99;
        setTimeout(function () {
          window.document.body.style.opacity = 1;
        }, 23)
    },
    updatePreview : function(x, y, width, height, successFunction, errorFunction) {
      cordova.exec(successFunction, errorFunction, 'backgroundvideo', 'updatePreview', [x, y, width, height]);
    },
    stop : function(successFunction, errorFunction) {
        cordova.exec(successFunction, errorFunction, 'backgroundvideo','stop', []);
    },
    stopPreview : function(successFunction, errorFunction) {
        cordova.exec(successFunction, errorFunction, 'backgroundvideo','stopPreview', []);
    },
    startPreview : function(successFunction, errorFunction) {
        cordova.exec(successFunction, errorFunction, 'backgroundvideo','startPreview', []);
    }
};

module.exports = backgroundvideo;
