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
    const urlList = [
        "https://rentry.org/",
        /* "LibreWolf Can’t Open This Page"
         * AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
         * I HATE THE ANTICHRIST
         */
        //"https://pastebin.com/",
    ];

    window.inliner_main = () => {
        // Convert text links to <a> links
        var iterator = document.createNodeIterator(
            document.documentElement,
            NodeFilter.SHOW_TEXT,
            { acceptNode: function(node) { return NodeFilter.FILTER_ACCEPT; }}
        );

        var nodeList = [];
        var currentNode;
        const regexList = urlList.map(url => new RegExp(url + "\\w*"));
        //const regex = /https:\/\/rentry.org\/\w*/;
        while ((currentNode = iterator.nextNode())) {
            //const match = regex.exec(currentNode.nodeValue);
            //if (match == null) { continue; }
            //nodeList.push(currentNode);
            for (const regex of regexList) {
                const match = regex.exec(currentNode.nodeValue);
                if (match) {
                    nodeList.push({ node: currentNode, match: match });
                    break;
                }
            }
        }

        console.log(`--- indexer # found ${nodeList.length} links`);

        //for (var i of nodeList) {
        //    const match = regex.exec(i.nodeValue);

        //    var tempDiv = document.createElement('div');
        //    tempDiv.innerHTML = 
        //        i.nodeValue.replace(
        //            match[0],
        //            `<a href="${match[0]}">` + match[0] + '</a>'
        //        )
        //    ;

        //    i.replaceWith(tempDiv);
        //}

        for (const item of nodeList) {
            const { node, match } = item;

            const tempDiv = document.createElement('div');
            tempDiv.innerHTML = 
                node.nodeValue.replace(
                    match[0],
                    `<a href="${match[0]}">${match[0]}</a>`
                )
            ;

            node.replaceWith(tempDiv);
        }

        // Actual inlining
        const links = document.querySelectorAll('a');

        links.forEach(link => {
            const href = link.getAttribute('href');
            
            if (href && urlList.some(url => href.startsWith(url))) {
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
