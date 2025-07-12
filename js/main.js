const Zooming = require('zooming');
const Turbolinks = require('turbolinks');
Turbolinks.start();

document.addEventListener('turbolinks:load', () => {
    new Zooming({
        bgColor: '#131516',
        customSize: '100%',
        enableGrab: false,
        onBeforeClose: (e) => {
            e.style['border-radius'] = '';
        },
        onBeforeOpen: (e) => {
            e.style['border-radius'] = '0';
        },
        scaleBase: 0.9,
        scaleExtra: 0,
    }).listen('img[data-action="zoom"]');
});
