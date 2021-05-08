#!/usr/bin/env ruby
# encoding: UTF-8
# frozen_string_literal: true

=begin
  
  Script qui permet de "builder" un fichier Markdown, c'est-à-dire
  de produire le fichier HTML ou le fichier PDF avec la commande
  CMD-B

  TODO
    * Pouvoir prendre la première balise h1 pour créer le titre
      du document (ou trouver la balise)

=end

require 'kramdown'
require 'sass'

FILE_PATH   = ARGV[0]
FORMAT_PDF  = ARGV[1] == '-pdf'
FOLDER      = File.dirname(FILE_PATH)
AFFIXE      = File.basename(FILE_PATH, File.extname(FILE_PATH))


# 
# Retourne le chemin d'accès au fichier de même affixe avec 
# l'extension +ext+
# 
def file_with_ext(ext)
  File.join(FOLDER,"#{AFFIXE}.#{ext}")
end



KRAMDOWN_METHOD = FORMAT_PDF ? :to_pdf : :to_html

#
# Fichier HTML de destination
# (même pour le format PDF)
#
HTML_DEST_PATH = file_with_ext('html')

puts "\n*** Production du fichier #{FORMAT_PDF ? 'PDF' : 'HTML'} ***"

# 
# Un rappel de la syntaxe markdown étendue par kramdown
# 
puts "\nRappel de syntaxe Kramdown"
puts "--------------------------"
puts "On place une ligne '{: .class #id key=\"value\"}' SOUS une ligne pour\najouter ces attributs."
puts "On place \n- TOC\n{:toc}\n… pour obtenir une table des matières "
puts "(utiliser '1. TOC' pour qu'elle soit numérotée"

# 
# Existe-t-il un fichier ERB de même nom ? Si oui, on le prend comme
# fichier template
# 
puts "\nTemplate (modèle)"
puts "-----------------"
TEMPLATE_PATH = 
if File.exists?(file_with_ext('erb'))
  puts "Utilisation du template '#{AFFIXE}.erb'."
  file_with_ext('erb')
else
  puts "On peut créer un modèle HTML avec un fichier #{AFFIXE}.erb contenant '<%= @body %>'."
  puts "Pour le titre, voir le template de ce dossier (ci-dessous)"
  puts "Puisqu'il n'est pas défini, je prends 'template.erb' dans mon dossier (#{__dir__})."
  File.join(__dir__,'template.erb')
end

#
# Existe-t-il du code CSS pour styler le document
# 
puts "\nCode CSS (aspect)"
puts "-----------------"
CSS_CODE =
if File.exists?(file_with_ext('css'))
  File.read(file_with_ext('css')).force_encoding('utf-8')
elsif File.exists?(file_with_ext('sass'))
  sass_code = File.readfile_with_ext('sass')
  data_compilation = { line_comments: false, style: :compressed, syntax: :sass }
  Sass.compile(sass_code, data_compilation)
else
  puts "On peut créer un fichier #{AFFIXE}.css ou #{AFFIXE}.sass pour définir les styles du document final."
  puts "Si un fichier template #{AFFIXE}.erb est utilisé, ajouter dedans __CSS__ à l'endroit où le code css doit être mis (il possèdera sa balise <style>)."
  File.read(File.join(__dir__,'github.css')).force_encoding('utf-8')
end

#
# Le template pour obtenir un document complet
# 
template_code = File.read(TEMPLATE_PATH).force_encoding('utf-8')
template_code = template_code.sub(/__CSS__/, CSS_CODE)

#
# Options kramdown
# 
KRAMDOWN_OPTIONS = {
  header_offset:    0,  # pour que '#' fasse un chapter
  template: "string://#{template_code}",   # pour avoir un document entier
}


str   = File.read(FILE_PATH).force_encoding('utf-8')
code  = Kramdown::Document.new(str, KRAMDOWN_OPTIONS).to_html
File.open(HTML_DEST_PATH,'wb'){|f|f.write(code)}


if FORMAT_PDF
  PDF_DEST_PATH = file_with_ext('pdf')
  res = `/usr/local/bin/wkhtmltopdf "file://#{HTML_DEST_PATH}" "#{PDF_DEST_PATH}" 2>&1`
  File.delete(HTML_DEST_PATH)
end