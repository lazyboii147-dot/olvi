(function() {
    window.XMLHttpRequest = class extends XMLHttpRequest {
        open(method, url) {
            if (url.includes('OneCollector')) url = 'http://localhost:8080/OneCollector/1.0/';
            super.open(method, url);
        }
    };
})();
