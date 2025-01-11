// ==UserScript==
// @name        Container (ctrl+p)
// @namespace   Violentmonkey Scripts
// @match       *://*/*
// @grant       none
// @version     1.0
// @author      Anon
// @description Creates a floating container where other scripts can register themselfs. The idea is that some functionalities should only be ran if the user explicitly asks for it.
// ==/UserScript==

(function() {
    'use strict';

    const containerHTML = `
        <div id="violent-monkey-manual-script-container" style="
            width: 200px;
            position: fixed;
            top: 20px;
            right: 20px;
            background-color: #f0f0f0;
            border: 1px solid #ccc;
            padding: 10px;
            z-index: 1000;
            display: none;
        ">
            <div style="
                font-weight: bold;
                margin-bottom: 5px;
            ">
                Violentmonkey Manual Script Container
            </div>
            <hr/>
            <div id="violent-monkeys-manual-script-container-main">
            </div>
        </div>
    `;
    document.body.insertAdjacentHTML('beforeend', containerHTML);


    // Add event listener for Ctrl + P to toggle the container
    document.addEventListener('keydown', function(e) {
        if (e.ctrlKey && e.code === 'KeyP') {
            e.preventDefault();
            (function toggleContainer() {
                const container = document.getElementById('violent-monkey-manual-script-container');
                container.style.display = container.style.display === 'none' ? 'block' : 'none';
            })();
        }
    });

    window.addContainerFunctionality = function(buttonText, callback) {
        const containerMain = document.getElementById('violent-monkeys-manual-script-container-main');

        const functionalityHTML = `
            <div style="margin-bottom: 5px;">
                <button onclick="(${callback})();" style="
                    color: white;
                    background: red;
                    width: 100%;
                ">${buttonText}</button>
            </div>
        `;
        containerMain.insertAdjacentHTML('beforeend', functionalityHTML);
    };

    document.dispatchEvent(new CustomEvent('violent-monkey-container-ready', {}));
    console.log("--- container initialized");
})();

/* Standard way to register a funtionality from another script:
 */
//    // Container loaded firsts
//    if (typeof window.addContainerFunctionality === 'function') {
//        addContainerFunctionality('<functionality-name>', 'window.<my>_main');
//    } else { // We must wait for the container to load
//        document.addEventListener('violent-monkey-container-ready', function(e) {
//            addContainerFunctionality('<functionality-name>', 'window.<my>_main');
//        });
//    }
