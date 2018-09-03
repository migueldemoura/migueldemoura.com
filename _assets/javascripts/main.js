//= require turbolinks/dist/turbolinks.js
//= require zooming/build/zooming.js

/* global Zooming */

document.addEventListener('turbolinks:load', () => {
  new Zooming({
    customSize: '100%',
    scaleBase: 0.9,
    scaleExtra: 0,
    enableGrab: false,
    onBeforeOpen: (e) => e.style['border-radius'] = '0',
    onBeforeClose: (e) => e.style['border-radius'] = ''
  }).listen('img[data-action="zoom"]');
})
