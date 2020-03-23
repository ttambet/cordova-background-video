var cordova = require('cordova');

var backgroundvideo = {
    initPreview: function(camera, x, y, width, height, successFunction, errorFunction) {
        cordova.exec(successFunction, errorFunction, 'backgroundvideo', 'initPreview', [camera, x, y, width, height]);
        window.document.body.style.opacity = .99;
        setTimeout(function () {
          window.document.body.style.opacity = 1;
        }, 23)
    },
    enablePreview : function(successFunction, errorFunction) {
        cordova.exec(successFunction, errorFunction, 'backgroundvideo','enablePreview', []);
    },
    disablePreview : function(successFunction, errorFunction) {
        cordova.exec(successFunction, errorFunction, 'backgroundvideo','disablePreview', []);
    },
    updatePreview: function(x, y, width, height, successFunction, errorFunction) {
      cordova.exec(successFunction, errorFunction, 'backgroundvideo', 'updatePreview', [x, y, width, height]);
    },
    startRecording: function(filename, successFunction, errorFunction) {
      cordova.exec(successFunction, errorFunction, 'backgroundvideo', 'startRecording', [filename]);
    },
    stopRecording: function(successFunction, errorFunction) {
      cordova.exec(successFunction, errorFunction, 'backgroundvideo', 'stopRecording', []);
    }
};

module.exports = backgroundvideo;
