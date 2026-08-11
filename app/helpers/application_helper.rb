module ApplicationHelper
  def is_last?(index, collection)
    index == collection.size - 1
  end

  def language_code(translation)
    language = translation.language.name
    case language
    when "Tibetan"
      "bo"
    when "English"
      "en"
    when "French"
      "fr"
    when "German"
      "de"
    when "Spanish"
      "es"
    when "Portuguese"
      "pt"
    else
      language.downcase
    end
  end

  def file_icon_path(file)
    if file.representable?
      file.representation(resize_to_limit: [ 100, 100 ])
    else
      extension = File.extname(file.filename.to_s).downcase.delete(".")
      case extension
      when "doc", "docx"
        "icons/doc-file.svg"
      when "indd"
        "icons/indd-file.svg"
      when "pdf"
        "icons/pdf-file.svg"
      end
    end
  end

  def file_icon(file)
    icon_path = file_icon_path(file)
    if icon_path
      image_tag icon_path, class: "w-8 h-8"
    else
      '<svg class="w-8 h-8 text-gray-400 group-hover:text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
      </svg>'
    end
  end

  # Pill de date de dernière modification d'un fichier (FileLocation#mtime),
  # pour distinguer les versions datées sans se perdre. Rendu discret.
  def file_date_pill(location, css: "")
    return if location&.mtime.blank?

    content_tag(:span,
      "modifié le #{location.mtime.strftime('%d/%m/%Y')}",
      class: "inline-flex items-center rounded-full bg-stone-100 text-stone-500 px-2 py-0.5 text-[11px] #{css}",
      title: "Dernière modification : #{location.mtime.strftime('%d/%m/%Y %H:%M')}")
  end

  def language_flag(language_name)
    case language_name.downcase
    when /tibetan/
      "🇹🇧"  # Drapeau tibétain (approximatif)
    when /english/
      "🇺🇸"  # Drapeau américain pour l'anglais
    when /french/
      "🇫🇷"  # Drapeau français
    when /spanish/
      "🇪🇸"  # Drapeau espagnol
    when /portuguese/
      "🇵🇹"  # Drapeau portugais
    when /german/
      "🇩🇪"  # Drapeau allemand
    else
      "🏳️"   # Drapeau blanc par défaut
    end
  end
end
