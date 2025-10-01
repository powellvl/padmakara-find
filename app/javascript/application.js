// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";
import TomSelect from "tom-select";

import "filters";

document.addEventListener("turbo:load", function () {
  // TomSelect pour les select multiples
  document.querySelectorAll(".tomselect").forEach((element) => {
    new TomSelect(element, {
      plugins: ["remove_button"],
      maxItems: null,
    });
  });

  // Menu utilisateur
  const userMenuButton = document.querySelector("#user-menu-button");
  const userMenu = document.querySelector("#user-menu");

  if (userMenuButton && userMenu) {
    userMenuButton.addEventListener("click", function () {
      userMenu.classList.toggle("hidden");
    });
  }
});
