# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "controllers", preload: true
pin "tom-select", to: "https://ga.jspm.io/npm:tom-select@2.2.2/dist/js/tom-select.complete.js"
pin "@deltablot/dropzone", to: "@deltablot--dropzone.js" # @7.2.0
pin_all_from "app/javascript/controllers", under: "controllers"

pin "tibetan-to-phonetics", to: "https://cdn.jsdelivr.net/npm/tibetan-to-phonetics@0.12.0/lib/esm/index.js"
pin "tibetan-normalizer", to: "https://cdn.jsdelivr.net/npm/tibetan-normalizer@0.2.0/dist/tibetan-normalizer.esm.js"
pin "tibetan-syllable-parser", to: "https://cdn.jsdelivr.net/npm/tibetan-syllable-parser@1.2.0/lib/esm/index.js"
pin "tibetan-unicode-converter", to: "https://cdn.jsdelivr.net/npm/tibetan-unicode-converter@1.0.0/lib/esm/index.js"
pin "tibetan-ewts-converter", to: "https://cdn.jsdelivr.net/npm/tibetan-ewts-converter@1.0.1/src/EwtsConverter.mjs"
