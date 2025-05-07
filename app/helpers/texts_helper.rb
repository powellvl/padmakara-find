module TextsHelper
  def display_text_cover(text, options = {})
    cover = text.preferred_cover

    if cover.present?
      if cover.content_type.start_with?("image/")
        # Si c'est une image directe (cover générée)
        image_tag(url_for(cover), alt: "Cover pour #{text.title_tibetan}", class: options[:class])
      elsif cover.content_type == "application/pdf"
        # Si c'est un PDF, on affiche un placeholder avec indication
        content_tag(:div, class: "text-cover-placeholder #{options[:class]}") do
          tag.svg(viewBox: "0 0 210 297", fill: "none", xmlns: "http://www.w3.org/2000/svg", class: "w-full h-full") do
            tag.path(d: "M30 30 H180 V267 H30 V30", class: "fill-white stroke-gray-200") +
            tag.text("PDF", x: "105", y: "148", "text-anchor": "middle", class: "fill-gray-400 font-serif", "font-size": "24")
          end
        end
      end
    else
      # Aucune cover disponible
      content_tag(:div, class: "text-cover-placeholder #{options[:class]}") do
        tag.svg(viewBox: "0 0 210 297", fill: "none", xmlns: "http://www.w3.org/2000/svg", class: "w-full h-full") do
          tag.path(d: "M30 30 H180 V267 H30 V30", class: "fill-white stroke-gray-200") +
          tag.text("No Cover", x: "105", y: "148", "text-anchor": "middle", class: "fill-gray-400 font-serif", "font-size": "18")
        end
      end
    end
  end
end
