const Zooming = require('zooming');
const Turbolinks = require('turbolinks');
Turbolinks.start();

document.addEventListener('turbolinks:load', () => {
    new Zooming({
        bgColor: '#131516',
        customSize: '100%',
        scaleBase: 0.9,
        scaleExtra: 0,
        enableGrab: false,
        onBeforeOpen: (e) => {
            e.style['border-radius'] = '0';
        },
        onBeforeClose: (e) => {
            e.style['border-radius'] = '';
        },
    }).listen('img[data-action="zoom"]');
});
