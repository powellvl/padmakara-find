import { Controller } from "@hotwired/stimulus";

import { EwtsConverter } from "tibetan-ewts-converter";
let ewts = new EwtsConverter();

import { TibetanToPhonetics } from "tibetan-to-phonetics";
import { TibetanUnicodeConverter } from "tibetan-unicode-converter";

export default class extends Controller {
  static targets = ["tibetanInput", "phoneticsInput", "wylieInput"];

  connect() {
    var phonetics = new TibetanToPhonetics({
      capitalize: true,
    });

    const updatePhonetics = (tibetan) => {
      if (this.hasPhoneticsInputTarget && this.phoneticsInputTarget) {
        this.phoneticsInputTarget.value = phonetics.convert(tibetan);
      }
    };

    const updateWylie = (tibetan) => {
      if (this.hasWylieInputTarget && this.wylieInputTarget) {
        this.wylieInputTarget.value = ewts.to_ewts(tibetan);
      }
    };

    // When pasting text in #text_title_tibetan that doesn't contain tibetan characters
    // then automatically convert ANSI to Unicode
    this.tibetanInputTarget.addEventListener("paste", (event) => {
      event.preventDefault();
      const pastedText = event.clipboardData.getData("text");
      const input = event.target;
      const start = input.selectionStart;
      const end = input.selectionEnd;
      const currentValue = input.value;

      // Determine the text to insert based on whether it contains Tibetan characters
      let textToInsert;
      if (
        pastedText.match(
          /^[^\u{f00}-\u{fda}\u{f021}-\u{f042}\u{f162}-\u{f588}]*$/u
        )
      ) {
        const converter = new TibetanUnicodeConverter(pastedText);
        textToInsert = converter.convert();
      } else {
        textToInsert = pastedText;
      }

      // Insert the text at the cursor position
      const newValue = currentValue.slice(0, start) + textToInsert + currentValue.slice(end);
      input.value = newValue;

      // Update cursor position to be after the inserted text
      const newCursorPosition = start + textToInsert.length;
      input.setSelectionRange(newCursorPosition, newCursorPosition);

      updateWylie(input.value);
      updatePhonetics(input.value);
    });

    // When #text_title_tibetan changes, automatically update #text_title_phonetics
    // with the generated phonetics of the tibetan text
    this.tibetanInputTarget.addEventListener("input", () => {
      updateWylie(this.tibetanInputTarget.value);
      updatePhonetics(this.tibetanInputTarget.value);
    });
  }
}
