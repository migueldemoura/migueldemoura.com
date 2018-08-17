// ==UserScript==
// @name         Finance Portal Part 2 Demo
// @namespace    https://miguedemoura.com
// @version      0.1
// @description  Data Spoof for Demo
// @author       Miguel de Moura
// @match        https://www.acesso.gov.pt/v2/*
// @match        https://sitfiscal.portaldasfinancas.gov.pt/*
// @grant        none
// ==/UserScript==

(function() {
  'use strict';

  let realNif = '';
  let realPassword = '';
  let spoofedGreeting = 'Boa noite';
  let spoofedNif = '600084779';
  let spoofedName = 'AUTORIDADE TRIBUTÁRIA E ADUANEIRA';

  if (window.location.href === 'https://www.acesso.gov.pt/v2/login') {
    let xsrf_token = document.querySelector('input[name="_csrf"]').value;
    let realForm = document.createRange().createContextualFragment(`
      <form name="realForm" style="display: none" action="login" method="POST">
        <input name="partID" value="PFAP">
        <input name="authVersion" value="2">
        <input name="_csrf" value="${xsrf_token}">
        <input name="selectedAuthMethod" value="N">
        <input name="username" value="${realNif}">
        <input name="password" value="${realPassword}">
        <button type="submit" name="sbmtLogin" value="Entrar">
      </form>
    `);

    document.body.appendChild(realForm);

    document.querySelector('#sbmtLogin').onclick = function () {
      document.realForm.submit();
      return false;
    };
  } else if (window.location.href.startsWith('https://sitfiscal.portaldasfinancas.gov.pt/geral')) {
    document.querySelector('#cumprimento').innerText = `${spoofedGreeting}, ${spoofedName}`;
    document.querySelector('.user-nif').innerHTML = `<strong>NIF:</strong> ${spoofedNif}`;
  }
})();
