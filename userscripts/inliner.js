// ==UserScript==
// @name        Inliner
// @namespace   Violentmonkey Scripts
// @match       *://*/*
// @grant       none
// @version     1.0
// @author      Anon
// @description The primary use of this script is to enhance the SingleFile extension. Currently only Rentry links work (as thats all i needed).
// ==/UserScript==

(function() {
    window.inliner_main = () => {
        // Convert text links to <a> links
        var iterator = document.createNodeIterator(
            document.documentElement,
            NodeFilter.SHOW_TEXT,
            { acceptNode: function(node) { return NodeFilter.FILTER_ACCEPT; }}
        );

        var nodeList = [];
        var currentNode;
        const regex = /https:\/\/rentry.org\/\w*/
        while ((currentNode = iterator.nextNode())) {
            const match = regex.exec(currentNode.nodeValue);
            if (match == null) { continue; }
            nodeList.push(currentNode);
        }

        console.log(`--- indexer # found ${nodeList.length} links`);

        for (var i of nodeList) {
            const match = regex.exec(i.nodeValue);

            var tempDiv = document.createElement('div');
            tempDiv.innerHTML = 
                i.nodeValue.replace(
                    match[0],
                    `<a href="${match[0]}">` + match[0] + '</a>'
                )
            ;

            i.replaceWith(tempDiv);
        }

        // Actual inlining
        const links = document.querySelectorAll('a');

        links.forEach(link => {
            const href = link.getAttribute('href');
            
            if (href && href.startsWith('https://rentry.org/')) {
                const iframeHTML = `
                    <iframe
                        src="${href}"
                        style="width: 100%; height: 500px; border: none;"
                        loading="lazy">
                    </iframe>
                `;
                link.parentNode.insertAdjacentHTML('beforeend', iframeHTML);
            }

            console.log("--- inliner # inlined link");
        });
    }

    if (typeof window.addContainerFunctionality === 'function') {
        addContainerFunctionality('Inline links', 'window.inliner_main');
    } else {
        document.addEventListener('violent-monkey-container-ready', function(e) {
            addContainerFunctionality('Inline links', 'window.inliner_main');
        });
    }
})();
