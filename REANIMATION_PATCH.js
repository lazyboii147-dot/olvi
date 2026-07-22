(function() {
    const originalFetch = window.fetch;
    window.fetch = function(url, options) {
        if (url.includes('OneCollector') || url.includes('bing.com')) {
            console.log("[!] Gopher redirecting...");
            return originalFetch('http://localhost:8080/OneCollector/1.0/', options);
        }
        return originalFetch.apply(this, arguments);
    };
})();
