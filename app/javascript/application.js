// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";
import TomSelect from "tom-select";
import "search";

document.addEventListener("turbo:load", function () {
  document.querySelectorAll(".tomselect").forEach((element) => {
    new TomSelect(element, {
      plugins: ["remove_button"],
      maxItems: null,
    });
  });
  document
    .querySelector("#user-menu-button")
    .addEventListener("click", function () {
      document.querySelector("#user-menu").classList.toggle("hidden");
    });
});
