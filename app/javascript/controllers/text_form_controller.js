import { Controller } from "@hotwired/stimulus";

import { TibetanToPhonetics } from "tibetan-to-phonetics";
import TibetanUnicodeConverter from "tibetan-unicode-converter";

export default class extends Controller {
  static targets = ["tibetanInput", "phoneticsInput"];

  connect() {
    var phonetics = new TibetanToPhonetics({
      capitalize: true,
    });

    const updatePhonetics = (tibetan) => {
      if (this.hasPhoneticsInputTarget && this.phoneticsInputTarget) {
        this.phoneticsInputTarget.value = phonetics.convert(tibetan);
      }
    };

    // When pasting text in #text_title_tibetan that doesn't contain tibetan characters
    // then automatically convert ANSI to Unicode
    this.tibetanInputTarget.addEventListener("paste", (event) => {
      event.preventDefault();
      const pastedText = event.clipboardData.getData("text");
      if (
        pastedText.match(
          /^[^\u{f00}-\u{fda}\u{f021}-\u{f042}\u{f162}-\u{f588}]*$/u
        )
      ) {
        const converter = new TibetanUnicodeConverter(pastedText);
        event.target.value = converter.convert();
      } else {
        event.target.value = pastedText;
      }
      updatePhonetics(event.target.value);
    });

    // When #text_title_tibetan changes, automatically update #text_title_phonetics
    // with the generated phonetics of the tibetan text
    this.tibetanInputTarget.addEventListener("input", () => {
      updatePhonetics(this.tibetanInputTarget.value);
    });
  }
}
